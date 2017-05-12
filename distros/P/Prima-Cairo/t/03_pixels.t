#! /usr/bin/perl
use strict;
use warnings;

use Test::More;

use Prima::noX11;
use Prima qw(Cairo);

plan tests => 25;

############# rgb24 

my $original = Prima::Image->create(
	width    => 2,
	height   => 2,
	type     => im::bpp24,
	data     => "\x10\x20\x30\x40\x50\x60\x70\x80\x90\xa0\xb0\xc0",
	lineSize => 6,
);

my $surface = $original->to_cairo_surface;
ok( $surface->status eq 'success', 'cairo rgb24 surface ok');
ok( $surface->get_format eq 'rgb24', 'type is rgb24');

my $image = $surface->to_prima_image;
ok( $image && $image->data eq $original->data, "prima bpp24 image ok");

############# argb32 

$surface = Prima::Cairo::to_cairo_surface($original, 'argb32'); 
ok( $surface->status eq 'success', 'cairo argb32 surface ok');
ok( $surface->get_format eq 'argb32', 'type is argb32');

$image = $surface->to_prima_image;
ok( $image && $image->data eq $original->data, "prima argb32 image ok");

############# a8

$original = Prima::Image->create(
	width    => 4,
	height   => 2,
	type     => im::Byte,
	data     => "\x10\x20\x30\x40\x50\x60\x70\x80",
	lineSize => 4,
);

$surface = Prima::Cairo::to_cairo_surface($original, 'a8');
ok( $surface->status eq 'success', 'cairo a8 surface ok');
ok( $surface->get_format eq 'a8', 'type is a8');

$image = $surface->to_prima_image;
ok( $image && $image->data eq $original->data, "prima imByte image ok");

############# a1

$original = Prima::Image->create(
	width    => 32,
	height   => 2,
	type     => im::BW,
	data     => "\x19\x2A\x3B\x4C\x5D\x6E\x7F\x80",
	lineSize => 4,
);

$surface = Prima::Cairo::to_cairo_surface($original, 'a1');
ok( $surface->status eq 'success', 'cairo a1 surface ok');
ok( $surface->get_format eq 'a1', 'type is a1');

$image = $surface->to_prima_image;
ok( $image && $image->data eq $original->data, "prima imBW image ok");

my $s1 = Cairo::ImageSurface->create('rgb24', 32, 2);
my $c1 = Cairo::Context->create($s1);
$c1->set_source_rgb(1,1,1);
$c1->mask_surface($surface,0,0);
my $b1 = $s1->to_prima_image;
$b1->set( conversion => ict::None, type => im::BW );
ok( $b1->data eq ~$original->data, "a1 bit order");

############# argb32 / icon a1

$original = Prima::Icon->create(
	width       => 4,
	height      => 1,
	type        => im::bpp24,
	data        => "\x10\x20\x30\x40\x50\x60\x70\x80\x90\xa0\xb0\xc0",
	mask        => "\xc0\x00\x00\x00\x00\x00\x00\x00",
	maskType    => im::bpp1,
);
$surface = $original->to_cairo_surface;
ok( $surface->status eq 'success', 'cairo argb32 surface ok');
ok( $surface->get_format eq 'argb32', 'type is argb32');

$image = $original->dup;
Prima::Cairo::copy_image_data($image, $$surface, 0);
ok( $image && $image->data eq $original->data, "prima icon/a1 data ok");
ok( $image && $image->mask eq $original->mask, "prima icon/a1 mask ok");

my $s2 = Cairo::ImageSurface->create('rgb24', 4, 1);
my $c2 = Cairo::Context->create($s2);
$c2->set_source_rgb(1,1,1);
$c2->rectangle(0,0,4,1);
$c2->fill;
$c2->set_source_surface($surface,0,0);
$c2->paint;
my $b2 = $s2->to_prima_image;
ok( $b2->pixel(0,1) == $original->pixel(0,1) && $b2->pixel(0,2) == $original->pixel(0,2) , "icon/a1 saved pixels");
ok( $b2->pixel(0,0) == 0xffffff && $b2->pixel(1,0) == 0xffffff, "icon/a1 cleared pixels");

############# argb32 / icon a8

$original = Prima::Icon->create(
	width       => 4,
	height      => 1,
	type        => im::bpp24,
	data        => "\x10\x20\x30\x40\x50\x60\x70\x80\x90\xa0\xb0\xc0",
	mask        => "\x00\x01\xFE\xFF",
	maskType    => im::bpp8,
);
$surface = $original->to_cairo_surface;
ok( $surface->status eq 'success', 'cairo argb32 surface ok');
ok( $surface->get_format eq 'argb32', 'type is argb32');

$image = $surface->to_prima_image('Prima::Icon');
ok( $image && $image->data eq $original->data, "prima icon/a8 data ok");
ok( $image && $image->mask eq $original->mask, "prima icon/a8 mask ok");

$s2 = Cairo::ImageSurface->create('rgb24', 4, 1);
$c2 = Cairo::Context->create($s2);
$c2->set_source_rgb(1,1,1);
$c2->rectangle(0,0,4,1);
$c2->fill;
$c2->set_source_surface($surface,0,0);
$c2->paint;
$b2 = $s2->to_prima_image;
ok( $b2->pixel(0,1) == $original->pixel(0,1) && $b2->pixel(0,2) == $original->pixel(0,2) , "icon/a8 saved pixels");
ok( $b2->pixel(0,0) == 0xffffff && $b2->pixel(1,0) == 0xffffff, "icon/a8 cleared pixels");
