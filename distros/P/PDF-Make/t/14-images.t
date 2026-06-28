#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;
use File::Spec;

BEGIN {
    use_ok('PDF::Make::Document');
    use_ok('PDF::Make::Image');
    use_ok('PDF::Make::Canvas');
}

my $jpeg_path = File::Spec->catfile('t', 'fixtures', 'images', 'test.jpg');
my $png_path  = File::Spec->catfile('t', 'fixtures', 'images', 'test.png');

# JPEG loading
my $jpeg = PDF::Make::Image->from_file($jpeg_path);
ok($jpeg, 'JPEG loaded');
ok($jpeg->width > 0, 'JPEG has width');
ok($jpeg->height > 0, 'JPEG has height');
is($jpeg->format, 0, 'JPEG format = 0');
is($jpeg->components, 3, 'JPEG has 3 components');

# PNG loading
my $png = PDF::Make::Image->from_file($png_path);
ok($png, 'PNG loaded');
is($png->format, 1, 'PNG format = 1');

# Write to document
my $doc = PDF::Make::Document->new;
my $page = $doc->add_page(612, 792);
my $jpeg_num = $jpeg->write_to_doc($doc);
ok($jpeg_num > 0, 'JPEG written to doc');
$page->add_image('Im0', $jpeg_num);

my $png_num = $png->write_to_doc($doc);
ok($png_num > 0, 'PNG written to doc');
$page->add_image('Im1', $png_num);

# Verify PDF structure
my $canvas = PDF::Make::Canvas->new;
$canvas->image('Im0', 72, 500, 200, 200);
$canvas->image('Im1', 300, 500, 200, 200);
$page->set_content($canvas->to_bytes);

my $bytes = $doc->to_bytes;
like($bytes, qr/\/XObject/, 'PDF has /XObject');
like($bytes, qr/\/DCTDecode/, 'PDF has /DCTDecode for JPEG');
like($bytes, qr/\/Subtype \/Image/, 'PDF has /Subtype /Image');

done_testing;
