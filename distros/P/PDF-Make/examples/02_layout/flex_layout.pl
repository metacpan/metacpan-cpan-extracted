#!/usr/bin/perl
# Feature: Flex-powered layout with auto-height and content-driven sizing
# Description: Demonstrates Layout::Flex backing Row::render — accurate
#              word-wrap height, weighted columns, gaps, and mixed content.
# Output: corpus/feature_examples/02_layout/flex_layout.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/02_layout');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/02_layout/flex_layout',
    configure => {
        h1 => { font => { size => 20, line_height => 26, colour => '#1a1a2e' } },
        h2 => { font => { size => 13, line_height => 18, colour => '#0f3460' } },
        text => { font => { size => 10, colour => '#333333' } },
    },
);

$pdf->add_page(page_size => 'Letter', padding => 36);

# ── 1. Auto-height: tall text forces the row taller ──────────────────────────

$pdf->add_h1(text => 'Flex Layout: auto-height rows');
$pdf->add_h2(text => '1. Auto-height — tall content drives row height');

my $lay1 = $pdf->layout;
my $r1   = $lay1->row;                      # no fixed height — flex computes it

$r1->cell(weight => 1, bg => '#dfe6e9', border => '#b2bec3', pad => 8)
   ->text(
       'Short cell. One line.',
       size => 10, colour => '#2d3436',
   );

$r1->cell(weight => 1, bg => '#ffeaa7', border => '#fdcb6e', pad => 8)
   ->text(
       'This cell contains a much longer paragraph of text that will wrap '
     . 'across several lines. The row height is determined by the tallest '
     . 'cell, so this column drives the overall height of the row no fixed '
     . 'height needed.',
       size => 10, colour => '#2d3436',
   );

$r1->cell(weight => 1, bg => '#dfe6e9', border => '#b2bec3', pad => 8)
   ->text(
       'Short cell again.',
       size => 10, colour => '#2d3436',
   );

$lay1->render;

# ── 2. Weighted columns (1:3:1) with auto-height ─────────────────────────────

$pdf->add_h2(text => '2. Weighted columns (1:3:1) — wide centre gets more text');

my $lay2 = $pdf->layout;
my $r2   = $lay2->row;

$r2->cell(weight => 1, bg => '#a29bfe', border => '#6c5ce7', pad => 8)
   ->text('Sidebar A', size => 10, colour => '#fff')
   ->text('Narrow.',   size => 9,  colour => '#dfe6e9');

$r2->cell(weight => 3, bg => '#ffffff', border => '#dfe6e9', pad => 8)
   ->text('Main content area', size => 11, colour => '#2d3436')
   ->text(
       'This centre column has weight 3 so it receives three times as much '
     . 'width as each sidebar. Because it is wider, its paragraph of text '
     . 'wraps to fewer lines than it would in a narrower column, demonstrating '
     . 'that the flex second-pass measurement uses the resolved width to count '
     . 'lines correctly.',
       size => 10, colour => '#636e72',
   );

$r2->cell(weight => 1, bg => '#fd79a8', border => '#e84393', pad => 8)
   ->text('Sidebar B', size => 10, colour => '#fff')
   ->text('Narrow.',   size => 9,  colour => '#ffeaa7');

$lay2->render;

# ── 3. Gap between columns ────────────────────────────────────────────────────

$pdf->add_h2(text => '3. Gap between columns');

my $lay3 = $pdf->layout;
my $r3   = $lay3->row(gap => 12);

for my $label ('Column A', 'Column B', 'Column C') {
    $r3->cell(weight => 1, bg => '#00b894', border => '#00cec9', pad => 8)
       ->text($label,           size => 10, colour => '#fff')
       ->text('Gap is 12pt.',   size => 9,  colour => '#dfe6e9');
}

$lay3->render;

# ── 4. Mixed font sizes in the same row ──────────────────────────────────────

$pdf->add_h2(text => '4. Mixed font sizes — height follows the largest');

my $lay4 = $pdf->layout;
my $r4   = $lay4->row;

$r4->cell(weight => 1, bg => '#f0f3f4', border => '#ced6e0', pad => 8)
   ->text('Small text (8pt)', size => 8, colour => '#636e72')
   ->text(
       'This column uses 8pt text so its measured line height is small. '
     . 'The row still expands to match the tallest neighbour.',
       size => 8, colour => '#636e72',
   );

$r4->cell(weight => 1, bg => '#f0f3f4', border => '#ced6e0', pad => 8)
   ->text('Large text (16pt)', size => 16, colour => '#2d3436')
   ->text(
       'This column uses 16pt — its wrapped height is taller so it drives '
     . 'the row height.',
       size => 16, colour => '#2d3436',
   );

$lay4->render;

# ── 5. Explicit height still works ───────────────────────────────────────────

$pdf->add_h2(text => '5. Explicit height override still respected');

my $lay5 = $pdf->layout;
my $r5   = $lay5->row(height => 50);

$r5->cell(weight => 1, bg => '#74b9ff', border => '#0984e3', pad => 8)
   ->text('Fixed-height row (50pt).', size => 10, colour => '#fff');
$r5->cell(weight => 2, bg => '#81ecec', border => '#00cec9', pad => 8)
   ->text(
       'Even with lots of text that would normally need more space, the row '
     . 'stays at 50pt because height was set explicitly.',
       size => 10, colour => '#2d3436',
   );

$lay5->render;

$pdf->save;
print "Created corpus/feature_examples/02_layout/flex_layout.pdf\n";
