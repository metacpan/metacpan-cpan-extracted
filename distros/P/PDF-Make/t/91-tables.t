#!/usr/bin/perl
# Phase 15 — Table detection.
#
# The aggregator already emits one line per baseline, so table detection
# is finding a run of ≥3 consecutive lines where each line has the same
# column count and all x-positions align within a 5-pt tolerance.  This
# test builds a 4-row × 3-col synthetic table plus a paragraph, and
# verifies only the table is reported.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use PDF::Make::Builder;
use PDF::Make::Document;
use PDF::Make::Page qw(:fonts);
use PDF::Make::Canvas;

my $b = PDF::Make::Builder->new(file_name => tmpnam() . '.pdf');

sub make_pdf {
    my ($setup) = @_;
    my $d = PDF::Make::Document->new;
    my $p = $d->add_page(612, 792);
    $p->add_std14_font('F1', HELVETICA);
    my $c = PDF::Make::Canvas->new;
    $setup->($c);
    $p->set_content($c->to_bytes);

    my $f = tmpnam() . '.pdf';
    open my $fh, '>:raw', $f or die $!;
    print $fh $d->to_bytes;
    close $fh;
    return $f;
}

# ── 4×3 grid plus a non-tabular paragraph below ───────
my @col_x = (72, 200, 400);     # three columns
my @row_y = (700, 680, 660, 640); # four rows
my @cells = (
    ['Name',  'Qty',  'Price'],
    ['Apple', '12',   '1.20'],
    ['Pear',  '5',    '2.50'],
    ['Plum',  '20',   '0.75'],
);

my $file = make_pdf(sub {
    my ($c) = @_;
    $c->BT->Tf('F1', 10);
    for my $ri (0..$#row_y) {
        for my $ci (0..$#col_x) {
            $c->Tm(1, 0, 0, 1, $col_x[$ci], $row_y[$ri])
              ->Tj($cells[$ri][$ci]);
        }
    }
    # Non-tabular paragraph well below the table so it forms a new block.
    $c->Tm(1, 0, 0, 1, 72, 500)->Tj('This paragraph is not a table.');
    $c->ET;
});

my @tables = $b->detect_tables($file);

is(scalar @tables, 1, 'one table detected');

my $t = $tables[0];
is($t->{rows}, 4, '4 rows');
is($t->{cols}, 3, '3 cols');

is_deeply($t->{cells}[0], ['Name', 'Qty',  'Price'], 'header row');
is_deeply($t->{cells}[1], ['Apple','12',   '1.20'],  'row 1');
is_deeply($t->{cells}[2], ['Pear', '5',    '2.50'],  'row 2');
is_deeply($t->{cells}[3], ['Plum', '20',   '0.75'],  'row 3');

cmp_ok($t->{x0}, '<=', 72, 'table bbox x0 ≤ first col');
cmp_ok($t->{x1}, '>=', 400, 'table bbox x1 covers last col');

unlink $file;

# ── Non-tabular paragraphs do not trigger a false positive ──
my $file2 = make_pdf(sub {
    my ($c) = @_;
    $c->BT->Tf('F1', 12);
    for my $y (700, 680, 660, 640) {
        $c->Tm(1, 0, 0, 1, 72, $y)
          ->Tj("line at $y with some text");
    }
    $c->ET;
});

my @t2 = $b->detect_tables($file2);
is(scalar @t2, 0, 'single-column paragraphs are not tables');

unlink $file2;

done_testing;
