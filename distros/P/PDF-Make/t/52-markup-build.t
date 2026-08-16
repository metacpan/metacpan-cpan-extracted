#!perl

# Markup to PDF.
#
# The assertions go through the extractor rather than stopping at "it wrote
# some bytes", because a build that silently drops a table row still writes a
# perfectly valid PDF.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use PDF::Make::Builder;
use PDF::Make::Markup::Parse;
use PDF::Make::Markup::Build;

my $dir = tempdir(CLEANUP => 1);
my $n   = 0;

sub render {
    my ($markup) = @_;
    local $ENV{SOURCE_DATE_EPOCH} = 1600000000;
    my $path = "$dir/doc" . $n++;
    my $root = PDF::Make::Markup::Parse->parse($markup);
    my $pdf  = PDF::Make::Markup::Build->build($root, file_name => $path);
    $pdf->save;
    return ("$path.pdf", $pdf);
}

sub text_of {
    my ($path, $pages) = @_;
    my $b = PDF::Make::Builder->new(file_name => "$dir/scratch");
    my $out = '';
    for my $p (0 .. ($pages || 1) - 1) {
        my $r = eval { $b->extract_structured($path, page => $p) } or next;
        for my $block ($r->blocks) {
            for my $line ($block->lines) {
                $out .= join(' ', map { $_->text } $line->words) . "\n";
            }
        }
    }
    return $out;
}

sub build_err {
    my ($markup, $like, $name) = @_;
    my $root = eval { PDF::Make::Markup::Parse->parse($markup) };
    if (!$root) { like $@, $like, $name; return }
    eval { PDF::Make::Markup::Build->build($root, file_name => "$dir/err") };
    like $@, $like, $name;
}

# ---- a whole document -------------------------------------------------------

subtest 'a document with every core shape in it' => sub {
    my ($path, $pdf) = render(<<'MK');
<doc page-size="A4" margin="36">
  <style h1="size:20;colour:#1a1a2e" text="size:10;colour:#333333" />
  <h1>Invoice 1042</h1>
  <text>Amount due: <b>1,240.00</b> by 30 September.</text>
  <hr />
  <row>
    <cell weight="2" pad="6" bg="#eeeeee">Acme Ltd</cell>
    <cell weight="1" pad="6" align="right">30 Sep</cell>
  </row>
  <table>
    <tr><th weight="3">Item</th><th align="right">Qty</th></tr>
    <tr><td>Widget</td><td align="right">12</td></tr>
  </table>
  <pagebreak/>
  <h2>Continued</h2>
</doc>
MK

    ok -s $path, 'wrote a file';
    is $pdf->page_count, 2, 'the pagebreak made a second page';

    my $text = text_of($path, 2);
    like $text, qr/Invoice 1042/, 'the heading is in the page content';
    like $text, qr/Amount due/,   'and the paragraph';
    like $text, qr/1,240\.00/,    'including the bold run';
    like $text, qr/30 September/, 'and the text after it';
    like $text, qr/Acme Ltd/,     'the row cells';
    like $text, qr/Widget/,       'the table body';
    like $text, qr/Item/,         'the table header';
    like $text, qr/Continued/,    'and the second page';
};

subtest 'styled runs register the font variants they asked for' => sub {
    my ($path) = render(
        '<doc><text>plain <b>bold</b> <i>italic</i> <span colour="#aa0000">red</span></text></doc>');
    open my $fh, '<:raw', $path or die $!;
    local $/;
    my $bytes = <$fh>;
    close $fh;
    like $bytes, qr/F_Helvetica_bold/,   'bold';
    like $bytes, qr/F_Helvetica_italic/, 'italic';
};

subtest 'unstyled text takes the single-font path' => sub {
    # Same words, one with markup that adds no styling. Both must produce
    # identical bytes: the plain path is the one existing documents depend
    # on, so ordinary text must not start going through the run machinery.
    my ($a) = render('<doc><text>one two three</text></doc>');
    my ($b) = render('<doc><text>one two three</text></doc>');
    open my $fa, '<:raw', $a or die $!; local $/; my $ba = <$fa>; close $fa;
    open my $fb, '<:raw', $b or die $!; my $bb = <$fb>; close $fb;
    is $ba, $bb, 'two renders of plain text are byte identical';
};

subtest 'page setup carries across a break' => sub {
    my ($path, $pdf) = render(
        '<doc page-size="Letter" margin="20"><text>a</text><pagebreak/><text>b</text></doc>');
    is $pdf->page_count, 2, 'two pages';
    my @pages = @{ $pdf->pages };
    is $pages[1]->page_size, 'Letter', 'the new page kept the paper size';
    is $pages[1]->padding, 20, 'and the margin';
};

subtest 'a page element starts its own page' => sub {
    my (undef, $pdf) = render(
        '<doc><text>one</text><page page-size="A5"><text>two</text></page></doc>');
    is $pdf->page_count, 2, 'two pages';
    is $pdf->pages->[1]->page_size, 'A5', 'with its own paper size';
};

subtest 'style defaults reach the blocks they name' => sub {
    my ($path) = render(<<'MK');
<doc>
  <style text="size:18;colour:#ff0000" />
  <text>styled by default</text>
</doc>
MK
    open my $fh, '<:raw', $path or die $!;
    local $/;
    my $bytes = <$fh>;
    close $fh;
    like $bytes, qr/\b18\b/, 'the configured size appears in the content stream';
    like $bytes, qr/1 0 0 rg/, 'as does the configured colour';
};

# ---- content models ---------------------------------------------------------

subtest 'the content model is enforced, with positions' => sub {
    build_err(qq{<doc>\n  <text><row><cell>x</cell></row></text>\n</doc>},
              qr/<row> cannot appear inside <text>, which holds text at line 2/,
              'a block inside a text element');

    build_err(qq{<doc>\n  <row><text>x</text></row>\n</doc>},
              qr/<text> cannot appear inside <row>, which holds cells at line 2/,
              'a non-cell inside a row');

    build_err(qq{<doc>\n  <table><td>x</td></table>\n</doc>},
              qr/<td> cannot appear inside <table>, which holds rows/,
              'a cell directly inside a table');

    build_err(qq{<doc>\n  loose words\n</doc>},
              qr/text directly inside <doc>: put it in a <text> block/,
              'bare text in a container');
};

subtest 'inline styling works inside a cell' => sub {
    my ($path) = render(
        '<doc><row><cell>Total <b>due</b> now</cell></row></doc>');
    open my $fh, '<:raw', $path or die $!;
    local $/;
    my $bytes = <$fh>;
    close $fh;
    like $bytes, qr/F_Helvetica_bold/,
        'the bold variant is registered from inside a cell';

    my $text = text_of($path);
    like $text, qr/Total/, 'the plain part is there';
    like $text, qr/due/,   'and the styled part';
};

subtest 'a box stacks blocks rather than flattening them' => sub {
    my ($path) = render(<<'MK');
<doc>
  <box pad="8" border="#cccccc">
    <h2>Heading in a box</h2>
    <text>A paragraph under it.</text>
    <text>And <b>another</b> one.</text>
  </box>
</doc>
MK
    my $text = text_of($path);
    like $text, qr/Heading in a box/, 'the heading rendered';
    like $text, qr/A paragraph under it/, 'the first paragraph';
    like $text, qr/another/, 'and the styled run in the second';
};

subtest 'a table has one set of columns, not one per row' => sub {
    # Weights are declared once, on the header, because that is where anyone
    # writing a table puts them. Laying each row out independently produced
    # two different column layouts stacked on each other, which is what "the
    # table is not aligned" looks like on the page.
    my ($path) = render(<<'MK');
<doc page-size="A4" margin="40">
  <table>
    <tr><th weight="3">Measure</th><th align="right">Now</th><th align="right">Before</th></tr>
    <tr><td>Orders shipped</td><td align="right">12,480</td><td align="right">11,120</td></tr>
    <tr><td>Returns</td><td align="right">0.7%</td><td align="right">0.9%</td></tr>
  </table>
</doc>
MK

    # Not $b: a lexical $b shadows the sort global, so every sort block below
    # would compare against this object's address instead of sorting.
    my $builder = PDF::Make::Builder->new(file_name => "$dir/scratch2");
    my $r = $builder->extract_structured($path, page => 0);

    my (%first_x, %right_x);
    for my $blk ($r->blocks) {
        for my $line ($blk->lines) {
            my @w = $line->words or next;
            my $y = sprintf '%.0f', $w[0]->y0;
            $first_x{$y} = $w[0]->x0 unless exists $first_x{$y};
            my $last = $w[-1];
            $right_x{$y} = $last->x1 if !exists $right_x{$y}
                                      || $last->x1 > $right_x{$y};
        }
    }

    my @ys = sort { $b <=> $a } keys %first_x;
    cmp_ok scalar @ys, '>=', 3, 'three rows on the page';

    my @lefts = map { $first_x{$_} } @ys;
    my $spread = (sort { $a <=> $b } @lefts)[-1] - (sort { $a <=> $b } @lefts)[0];
    cmp_ok $spread, '<', 1, 'every row starts its first column at the same x';

    my @rights = map { $right_x{$_} } @ys;
    my $rspread = (sort { $a <=> $b } @rights)[-1]
                - (sort { $a <=> $b } @rights)[0];
    cmp_ok $rspread, '<', 2,
        'and the last column shares a right edge across rows';
};

subtest 'a block the cell cannot hold is still refused' => sub {
    build_err('<doc><row><cell><row><cell>x</cell></row></cell></row></doc>',
              qr/<row> cannot appear inside <cell>/,
              'a row inside a cell');
};

subtest 'bad attributes stop the build' => sub {
    build_err('<doc><h1 size="huge">x</h1></doc>',
              qr/size 'huge' is not a number of points/, 'a bad length');
    build_err('<doc><img/></doc>', qr/<img> needs a src/, 'a missing src');
    build_err('<doc><bookmark/></doc>', qr/<bookmark> needs a title/,
              'a missing title');
};

# ---- the tag set and the builder agree --------------------------------------

subtest 'every tag the parser accepts is one the builder renders' => sub {
    my %sample = (
        doc       => '<doc></doc>',
        style     => '<doc><style text="size:9"/></doc>',
        page      => '<doc><page><text>x</text></page></doc>',
        pagebreak => '<doc><text>x</text><pagebreak/></doc>',
        header    => '<doc><header>top</header><text>x</text></doc>',
        footer    => '<doc><footer>foot</footer><text>x</text></doc>',
        p         => '<doc><p>x</p></doc>',
        text      => '<doc><text>x</text></doc>',
        hr        => '<doc><hr/></doc>',
        box       => '<doc><box pad="4" bg="#eee">x</box></doc>',
        img       => undef,   # needs a real image file; covered elsewhere
        row       => '<doc><row><cell>x</cell></row></doc>',
        cell      => '<doc><row><cell>x</cell></row></doc>',
        table     => '<doc><table><tr><td>x</td></tr></table></doc>',
        tr        => '<doc><table><tr><td>x</td></tr></table></doc>',
        th        => '<doc><table><tr><th>x</th></tr></table></doc>',
        td        => '<doc><table><tr><td>x</td></tr></table></doc>',
        bookmark  => '<doc><bookmark title="here"/><text>x</text></doc>',
        b         => '<doc><text>a <b>b</b></text></doc>',
        i         => '<doc><text>a <i>b</i></text></doc>',
        span      => '<doc><text>a <span size="12">b</span></text></doc>',
    );
    $sample{"h$_"} = "<doc><h$_>x</h$_></doc>" for 1 .. 6;

    for my $t (PDF::Make::Markup::Parse->tags) {
        my $name = $t->{name};
        ok exists $sample{$name}, "<$name> has a sample here"
            or next;
        next unless defined $sample{$name};
        my ($path) = eval { render($sample{$name}) };
        ok $path && -s $path, "<$name> renders" or diag $@;
    }
};

done_testing;
