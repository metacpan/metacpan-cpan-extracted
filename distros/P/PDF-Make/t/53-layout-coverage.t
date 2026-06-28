#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

# ── Layout with auto-height, alignment, bg, border ─────

my $f = tmpnam() . '.pdf';
END { unlink $f if $f && -f $f }

my $b = PDF::Make::Builder->new(file_name => $f);
$b->add_page(page_size => 'Letter');

# Create a layout (table)
my $layout = $b->layout(margin => 5);
isa_ok($layout, 'PDF::Make::Builder::Layout');

# Row 1: auto-height with bg and border
my $row1 = $layout->row;
isa_ok($row1, 'PDF::Make::Builder::Layout::Row');

my $c1 = $row1->cell(weight => 2, align => 'left', bg => '#EEEEEE', border => '#333333');
$c1->text('Left-aligned cell with background and border. ' x 5, size => 10);

my $c2 = $row1->cell(weight => 1, align => 'center', bg => '#DDDDFF');
$c2->text('Centered text in a cell.', size => 10);

my $c3 = $row1->cell(weight => 1, align => 'right');
$c3->text('Right-aligned text.', size => 10);

# Row 2: explicit height
my $row2 = $layout->row(height => 30);
my $c4 = $row2->cell;
$c4->text('Fixed height row');

# Row 3: cell with image content (measure_height path)
my $row3 = $layout->row;
my $c5 = $row3->cell;
$c5->text('Text above');
$c5->image('/dummy.png', h => 40);

# Render the layout
$layout->render;

$b->save;
ok(-f $f, 'layout PDF created');
ok(-s $f > 500, 'layout PDF has content');

# Read and verify
open my $fh, '<:raw', $f;
my $bytes = do { local $/; <$fh> };
close $fh;
like($bytes, qr/%PDF/, 'valid PDF');

# ── Cell measure_height edge cases ──────────────────────

# Cell with only text
{
    my $cell = PDF::Make::Builder::Layout::Cell->new(pad => 5);
    $cell->text('Hello world');
    # We need a mock font-like object for measure_height
    # Just verify the method exists and is callable
    ok($cell->can('measure_height'), 'cell has measure_height');
    ok($cell->can('render_content'), 'cell has render_content');
}

# Cell chainable text
{
    my $cell = PDF::Make::Builder::Layout::Cell->new;
    my $ret = $cell->text('One');
    is($ret, $cell, 'text() returns $self for chaining');
    my $ret2 = $cell->image('/foo.png');
    is($ret2, $cell, 'image() returns $self for chaining');
}

# ── Multiple rows with varied alignment ─────────────────

my $f2 = tmpnam() . '.pdf';
END { unlink $f2 if $f2 && -f $f2 }

my $b2 = PDF::Make::Builder->new(file_name => $f2);
$b2->add_page(page_size => 'A4');

my $lay = $b2->layout;

# Row with long wrapping text to trigger word-wrap + overflow
my $r = $lay->row;
my $wide = $r->cell(weight => 1, align => 'center');
$wide->text('Word ' x 80, size => 12);  # lots of words to force wrapping

my $narrow = $r->cell(weight => 1, align => 'right', border => '#000000', bg => '#FFCCCC');
$narrow->text('Short', size => 10);

$lay->render;
$b2->save;
ok(-f $f2, 'multi-alignment PDF created');
ok(-s $f2 > 500, 'multi-alignment PDF has content');

# ── Valign and pad options ──────────────────────────────

{
    my $cell = PDF::Make::Builder::Layout::Cell->new(
        valign => 'center',
        pad    => 10,
    );
    is($cell->{valign}, 'center', 'valign stored');
    is($cell->{pad}, 10, 'pad stored');
}

done_testing;
