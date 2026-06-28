#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

my $f = tmpnam() . '.pdf';
END { unlink $f if $f && -f $f }

my $b = PDF::Make::Builder->new(file_name => $f);
$b->add_page(page_size => 'Letter');

# ── Auto-height row ─────────────────────────────────────

my $cy = $b->page->cursor_y;
my $layout = $b->layout;
my $row = $layout->row;  # no explicit height
$row->cell(weight => 1)->text('Auto-height cell');
$row->cell(weight => 1)->text('Second cell with more text that may wrap');
$layout->render;
ok($b->page->cursor_y < $cy, 'auto-height row advances cursor');

# ── Right-aligned cell ──────────────────────────────────

$cy = $b->page->cursor_y;
my $layout2 = $b->layout;
my $row2 = $layout2->row(height => 40);
$row2->cell(weight => 1, align => 'right')
     ->text('Right-aligned text in cell');
$row2->cell(weight => 1, align => 'left')
     ->text('Left-aligned text');
$layout2->render;
ok($b->page->cursor_y < $cy, 'right-aligned cell renders');

# ── Center-aligned cell ─────────────────────────────────

$cy = $b->page->cursor_y;
my $layout3 = $b->layout;
my $row3 = $layout3->row(height => 35);
$row3->cell(weight => 1, align => 'center', bg => '#eee')
     ->text('Centered cell');
$layout3->render;
ok($b->page->cursor_y < $cy, 'center-aligned cell renders');

# ── Empty cells ──────────────────────────────────────────

my $layout4 = $b->layout;
my $row4 = $layout4->row(height => 20);
$row4->cell(weight => 1, bg => '#ddd');  # empty
$row4->cell(weight => 2)->text('Content');
$row4->cell(weight => 1);  # empty, no bg
$layout4->render;
ok(1, 'empty cells render');

# ── Multiple text items per cell ─────────────────────────

my $layout5 = $b->layout;
my $row5 = $layout5->row(height => 80);
$row5->cell(weight => 1, border => '#999', pad => 8)
     ->text('Title', size => 14, colour => '#333')
     ->text('Subtitle', size => 10, colour => '#666')
     ->text('Body text content', size => 9);
$layout5->render;
ok(1, 'multi-text cell renders');

# ── Row with border and background ──────────────────────

my $layout6 = $b->layout;
my $row6 = $layout6->row(height => 30, margin => 15);
$row6->cell(weight => 1, bg => '#3498db', border => '#2c3e50', pad => 5)
     ->text('Styled', colour => '#fff', size => 12);
$row6->cell(weight => 1, bg => '#2ecc71', border => '#27ae60', pad => 5)
     ->text('Cells', colour => '#fff', size => 12);
$layout6->render;
ok(1, 'styled row renders');

# ── Unequal weights ──────────────────────────────────────

my $layout7 = $b->layout;
my $row7 = $layout7->row(height => 25);
$row7->cell(weight => 1)->text('1');
$row7->cell(weight => 3)->text('3');
$row7->cell(weight => 1)->text('1');
$layout7->render;
ok(1, 'unequal weight cells render');

# ── Save and verify ──────────────────────────────────────

$b->save;
ok(-f $f, 'layout coverage PDF created');
ok(-s $f > 500, 'PDF has substantial content');

done_testing;
