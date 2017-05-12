use strict;
use warnings;
use Prima qw(Application Cairo PS::Printer);

sub draw
{
	my $b = shift;
	my $cr = $b->cairo_context;
	
	$cr->rectangle (10, 10, 40, 40);
	$cr->set_source_rgba (0, 1, 0, 0.8);
	$cr->fill;
	
	$cr->rectangle (30, 30, 40, 40);
	$cr->set_source_rgba (1, 0, 1, 0.8);
	$cr->fill;
	
	$cr->show_page;
}

print "DeviceBitmap(monochrome => 0)\n";
my $b = Prima::DeviceBitmap->create(width => 250, height => 250, monochrome => 0);
$b->clear;
draw($b);
$b->image->save('dbm-color.bmp');

print "DeviceBitmap(monochrome => 1)\n";
$b = Prima::DeviceBitmap->create(width => 250, height => 250, monochrome => 1);
$b->fillPattern(fp::CloseDot);
$b->bar(0,0,$b->size);
draw($b);
$b->image->save('dbm-mono.bmp');

print "Image\n";
$b = Prima::Image->create(width => 250, height => 250);
$b->begin_paint;
$b->clear;
draw($b);
$b->end_paint;
$b->save('image.bmp');

print "Application\n";

$b = $::application;
$b->begin_paint;
draw($b);
$b->end_paint;

print "PostScript\n";
$b = Prima::PS::File->create(file => 'test.ps');
$b->begin_doc;
draw($b);
$b->end_doc;
