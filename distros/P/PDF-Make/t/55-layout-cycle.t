#!perl

# Layout objects must be collectable.
#
# Layout holds its rows and each row points back at the layout; a row holds
# its cells and each cell points back at the row. Both are reference cycles,
# and reference counting never collects a cycle, so every laid-out row used to
# be leaked for the life of the process - around 90KB per document with a
# table. That is invisible in a script that renders one invoice and fatal in a
# server that renders them all day, which is exactly the shape of bug that
# only shows up in production.
#
# The back-references are weakened. These tests fail if either weakening is
# lost, including by someone reordering the property lists.

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(isweak);
use PDF::Make::Builder;

sub builder {
    my $b = PDF::Make::Builder->new(file_name => 'unsaved');
    $b->add_page(page_size => 'A4', padding => 36);
    return $b;
}

subtest 'the back-references are weak' => sub {
    my $b   = builder();
    my $lay = $b->layout;
    my $row = $lay->row;
    my $cell = $row->cell(weight => 1);

    my ($row_slot) = grep { ref $row->[$_] && $row->[$_] == $lay } 0 .. $#$row;
    ok defined $row_slot, 'the row does point back at its layout';
    ok isweak($row->[$row_slot]), '  and that reference is weak';

    my ($cell_slot) = grep { ref $cell->[$_] && $cell->[$_] == $row } 0 .. $#$cell;
    ok defined $cell_slot, 'the cell does point back at its row';
    ok isweak($cell->[$cell_slot]), '  and that reference is weak';
};

subtest 'a rendered layout is collected' => sub {
    my $b = builder();

    my ($row_ref, $cell_ref, $lay_ref);
    {
        my $lay = $b->layout;
        my $row = $lay->row;
        $row->cell(weight => 1)->text('left');
        $row->cell(weight => 2)->text('right');
        $lay->render;

        $lay_ref  = $lay;
        $row_ref  = $row;
        $cell_ref = $lay->rows->[0]->cells->[0];
        Scalar::Util::weaken($_) for $lay_ref, $row_ref, $cell_ref;
    }

    is $lay_ref,  undef, 'the layout was freed once it went out of scope';
    is $row_ref,  undef, 'so was the row';
    is $cell_ref, undef, 'and the cell';
};

subtest 'cells can still reach their row' => sub {
    my $b    = builder();
    my $lay  = $b->layout;
    my $row  = $lay->row(gap => 4);
    my $cell = $row->cell(weight => 3);

    is $cell->row, $row, 'the back-reference still works while the row lives';
    is $cell->row->gap, 4, '  including through it';
    is $row->layout, $lay, 'and a row can still reach its layout';
};

subtest 'repeated rendering does not accumulate' => sub {
    # A weak reference is easy to lose to a refactor, and RSS is the thing
    # anyone will actually notice, so measure it directly where we can.
    my $rss = sub {
        my $out = `ps -o rss= -p $$ 2>/dev/null`;
        return undef unless defined $out;
        $out =~ s/\D//g;
        return length $out ? $out + 0 : undef;
    };

    plan skip_all => 'ps not available for an RSS measurement'
        unless defined $rss->();

    my $render = sub {
        my $b   = builder();
        my $lay = $b->layout;
        for (1 .. 12) {
            my $row = $lay->row;
            $row->cell(weight => 3)->text('Line item');
            $row->cell(weight => 1)->text('9.99');
        }
        $lay->render;
        return $b->to_bytes;
    };

    $render->() for 1 .. 30;             # warm
    my $before = $rss->();
    $render->() for 1 .. 300;
    my $growth = $rss->() - $before;

    # Before the fix this was around 90KB per document, so 300 renders cost
    # tens of megabytes. Allow generous headroom for the allocator without
    # letting a real leak through.
    cmp_ok $growth, '<', 4096,
        "300 table renders grew RSS by ${growth}KB, not tens of megabytes";
};

done_testing;
