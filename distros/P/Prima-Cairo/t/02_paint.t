#! /usr/bin/perl
use strict;
use warnings;

use Test::More;

use Prima::noX11;
use Prima;
plan skip_all => 'No X display' if Prima::XOpenDisplay();

eval "use Prima qw(Application Cairo)";
die $@ if $@;

plan tests => 4;

sub draw
{
	my $b = shift;
	my $cr = $b->cairo_context;
	
	$cr->rectangle (1, 1, 4, 4);
	$cr->set_source_rgba (0, 1, 0, 0.8);
	$cr->fill;
	
	$cr->rectangle (3, 3, 4, 4);
	$cr->set_source_rgba (1, 0, 1, 0.8);
	$cr->fill;
	
	$cr->show_page;
}

my ($i1,$i2);
my $b = Prima::DeviceBitmap->create(width => 10, height => 10, monochrome => 0);
$b->fillPattern(fp::CloseDot);
$b->bar(0,0,$b->size);
$i1 = $b->image;
draw($b);
$i2 = $b->image;
ok( $i1->data ne $i2->data, "colored DeviceBitmap");

$b = Prima::DeviceBitmap->create(width => 10, height => 10, monochrome => 1);
$b->fillPattern(fp::CloseDot);
$b->bar(0,0,$b->size);
$i1 = $b->image;
draw($b);
$i2 = $b->image;
ok( $i1->data ne $i2->data, "monochrome DeviceBitmap");

SKIP: {
$::application->get_system_value( sv::LayeredWidgets ) or skip "ARGB not supported", 1;
$b = Prima::DeviceBitmap->create(width => 10, height => 10, type => dbt::Layered);
$b->fillPattern(fp::CloseDot);
$b->bar(0,0,$b->size);
$i1 = $b->icon;
draw($b);
$i2 = $b->icon;
ok(( $i1->data ne $i2->data) && ($i1->mask ne $i2->mask), "argb DeviceBitmap");
}

$b = Prima::Image->create(width => 250, height => 250);
$b->begin_paint;
$b->fillPattern(fp::CloseDot);
$b->bar(0,0,$b->size);
$b->end_paint;
$i1 = $b->data;
$b->begin_paint;
draw($b);
$b->end_paint;
$i2 = $b->data;
ok( $i1 ne $i2, "Image");

