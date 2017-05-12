use Test::More tests=>62;
use strict;

use GD;
use SVG::GD;

my $steps = 5;
my ($width,$height) = (200,200);
my $dwg;

ok($dwg = new GD::Image($width,$height),"new GD::Image");

my $col0 = $dwg->colorAllocate(1,3,200);
my $col1 = $dwg->colorAllocate(24,54,254);
ok(my $col2 = $dwg->colorAllocate(25,155,25),"colorAllocate");
my $col3 = $dwg->colorAllocate(255,0,0);
ok(defined $col0 && defined $col1 && defined $col2,"Allocated colors");
my $tag1 = $dwg->arc(50, 50, 50,50,0,0,$col1);
my $tag2 = $dwg->arc(10, 10, 4, 10,0,0,$col2);

my $tag3 = $dwg->rectangle(20,120,40,30,$col0);
ok(my $tag4 = $dwg->filledRectangle(120,120,40,70,$col3),"filledRectangle");


my @range = (0..50);

foreach  (@range) {
	my $c = $dwg->colorAllocate(
		int(rand(255)),
		int(rand(255)),
		int(rand(255))
	);

	my $p = $dwg->setPixel(
		int(rand($width)),
		int(rand($height)),
		$c);

	ok(defined $c and defined $p,"colorAllocate and setPixel");
}
#draw a line
ok($dwg->line(180,20,70,170,$dwg->colorAllocate(25,10,175)),"line and colorAllocate");

ok(my $pngout =  $dwg->png,"png out");
ok(my $wbmpout =  $dwg->wbmp($col3),"wbmp out");
ok(my $svgout = $dwg->svg,"svg out");
my $pngfile = 't/out.'.rand(100000).'.png';
my $wbmpfile = 't/out.'.rand(1000000).'.wbmp';
my $svgfile= 't/out.'.rand(1000000).'.svg';

if (-e $pngfile) {unlink $pngfile}  
if (-e $wbmpfile) {unlink $wbmpfile}  
if (-e $svgfile) {unlink $svgfile}  

#output png image
open OUT,">$pngfile" 
	|| die "Unable to open test output file '$pngfile'";

binmode OUT;
print OUT $pngout;
close OUT;
ok(-e $pngfile,"png file write test");

##output wbmp image
open OUT,">$wbmpfile" 
	|| die "Unable to open test output file '$wbmpfile'";

binmode OUT;
print OUT $wbmpout;
close OUT;
ok(-e $wbmpfile,"wbmp file write test");

#output svg image
open OUT,">$svgfile" 
	|| die "Unable to open test output file '$svgfile'";
ok(-e $svgfile,"svg file write test");

if (-e $pngfile) {unlink $pngfile}  
if (-e $wbmpfile) {unlink $wbmpfile}  
if (-e $svgfile) {unlink $svgfile}  

