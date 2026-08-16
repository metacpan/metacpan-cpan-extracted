#!perl

# Row height, and the two ways it used to go wrong.
#
# Both bugs below were found by rendering a realistic bank statement rather
# than a test fixture, which is the argument for having a corpus of real
# documents at all: a table where some cells are empty, and a header, are
# ordinary things that no unit test happened to combine.

use strict;
use warnings;
use Test::More;
use PDF::Make::Builder;

sub page_of {
    my $b = PDF::Make::Builder->new(file_name => 'unsaved');
    $b->add_page(page_size => 'A4', padding => 40);
    return $b;
}

subtest 'an empty cell does not make the row ten thousand points tall' => sub {
    # Layout::Flex hands a zero-height item the whole cross size back, so a
    # row containing one empty <td> measured 10000pt. The cursor ran off the
    # page, clamped to the top, and every following row drew in the same
    # place - a statement with ten transactions rendered nine of them on top
    # of the title.
    my $b = page_of();

    my @after;
    for my $case (
        [ 'full',      sub { $_[0]->cell(weight => 1)->text('a');
                             $_[0]->cell(weight => 1)->text('b') } ],
        [ 'one empty', sub { $_[0]->cell(weight => 1)->text('a');
                             $_[0]->cell(weight => 1) } ],
        [ 'all empty', sub { $_[0]->cell(weight => 1);
                             $_[0]->cell(weight => 1) } ],
    ) {
        my ($name, $build) = @$case;
        my $before = $b->page->cursor_y;
        my $lay = $b->layout;
        my $row = $lay->row;
        $build->($row);
        $lay->render;
        my $moved = $before - $b->page->cursor_y;

        cmp_ok $moved, '>', 0, "$name: the cursor moved down the page";
        cmp_ok $moved, '<', 100, "$name: by a sane amount, not by a page";
        push @after, $b->page->cursor_y;
    }

    ok $after[0] > $after[1] && $after[1] > $after[2],
        'each row starts below the one before it';
};

subtest 'ten rows with gaps in them stack in order' => sub {
    my $b = page_of();
    my @tops;
    for my $i (1 .. 10) {
        push @tops, $b->page->cursor_y;
        my $lay = $b->layout;
        my $row = $lay->row;
        $row->cell(weight => 2)->text("row $i");
        # every other row leaves a column blank, as a statement does
        if ($i % 2) { $row->cell(weight => 1)->text('12.40') }
        else        { $row->cell(weight => 1) }
        $lay->render;
    }

    my $descending = 1;
    for my $i (1 .. $#tops) {
        $descending = 0 if $tops[$i] >= $tops[$i - 1];
    }
    ok $descending, 'every row began lower than the last';
    cmp_ok $tops[-1], '>', 40, 'and the last one is still on the page';
};

subtest 'a header and footer actually draw their text' => sub {
    # add_page_header takes a callback, not a text argument. Passing
    # text => did nothing whatsoever, silently, so <header> and <footer>
    # rendered blank while the markup looked correct.
    require PDF::Make::Markup::Render;

    local $ENV{SOURCE_DATE_EPOCH} = 1600000000;
    my $bytes = PDF::Make::Markup::Render->render_markup(<<'MK');
<doc page-size="A4" margin="40">
  <header>Northern Mutual statement</header>
  <footer>Account 12-34-56</footer>
  <text>Body text.</text>
</doc>
MK

    my $b = PDF::Make::Builder->new(file_name => 'unsaved');
    open my $fh, '>:raw', '/tmp/pdfmake-hf-test.pdf' or die $!;
    print $fh $bytes;
    close $fh;

    my $r = $b->extract_structured('/tmp/pdfmake-hf-test.pdf', page => 0);
    my (%seen, %y);
    for my $blk ($r->blocks) {
        for my $line ($blk->lines) {
            my @w = $line->words or next;
            my $t = join ' ', map { $_->text } @w;
            $seen{$t} = 1;
            $y{$t} = $w[0]->y0;
        }
    }
    my ($header) = grep { /Northern Mutual/ } keys %seen;
    my ($footer) = grep { /12-34-56/ }        keys %seen;
    my ($body)   = grep { /Body text/ }       keys %seen;

    ok $header, 'the header text is on the page';
    ok $footer, 'the footer text is on the page';
    ok $body,   'and so is the body';

    if ($header && $footer && $body) {
        cmp_ok $y{$header}, '>', $y{$body},   'the header is above the body';
        cmp_ok $y{$footer}, '<', $y{$body},   'the footer is below it';
    }
    unlink '/tmp/pdfmake-hf-test.pdf';
};

done_testing;
