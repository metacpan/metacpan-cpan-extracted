#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use lib 'lib';

BEGIN {
    use_ok('Object::Proto');
    use_ok('PDF::Make::Builder');
}

use_ok('PDF::Make::Builder');

# Basic creation
my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
close $fh;

my $pdf = PDF::Make::Builder->new(
    file_name => $tmpfile,
    configure => {
        text => { font => { size => 11, family => 'Helvetica' } },
    },
);
ok($pdf, 'Builder created');

# Add page
$pdf->add_page(page_size => 'Letter');
my $page = $pdf->page;
ok($page, 'page created');
is($page->w, 612, 'Letter width');
is($page->h, 792, 'Letter height');

# Add text
$pdf->add_text(text => 'Hello from Builder');
ok(1, 'add_text succeeded');

# Add heading
$pdf->add_h1(text => 'Title');
ok(1, 'add_h1 succeeded');

# Add shapes
$pdf->add_line(fill_colour => '#000');
ok(1, 'add_line succeeded');

$pdf->add_box(fill_colour => '#336699', w => 100, h => 50);
ok(1, 'add_box succeeded');

# Page cursor moved
my $cursor_y = $page->cursor_y;
ok($cursor_y < $page->top_y, 'cursor advanced');

# Font metrics
my $font = $pdf->font;
ok($font, 'font accessible');
my $width = $font->measure_text('Hello');
ok($width > 0, 'text width > 0');

# Hex to RGB
my ($r, $g, $b) = $font->hex_to_rgb('#ff0000');
is($r, 1, 'hex red R=1');
is($g, 0, 'hex red G=0');

# Save
$pdf->save;
ok(-f $tmpfile, 'PDF file created');
ok(-s $tmpfile > 100, 'PDF file has content');

done_testing;
