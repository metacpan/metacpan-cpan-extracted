# this example tests correctness of bit transfer process from Prima to Cairo.
# I suspect there's something fishy as bits require mirroring (see rev_memcpy in Cairo.xs) 
use strict;
use warnings;
use Cairo;
use Prima qw(Cairo StdBitmap);

my $a = Prima::Image->new( width => 16, height => 16 );
$a->begin_paint;
$a->clear;
$a->clear;
$a->rectangle(0,0,15,15);
$a->lineWidth(3);
$a->ellipse(7,7,10,10);
$a->end_paint;
$a->type(im::BW);
my $a1 = Prima::Cairo::to_cairo_surface($a, 'a1');
$a1->write_to_png('a1.png');
$b = Prima::Image->load('a1.png') or die $@;
for ( my $y = 0; $y < $a->height; $y++) {
	for ( my $x = 0; $x < $a->width; $x++) {
		my $p = $b->pixel($x,$y);
		print $p ? "*" : " ";
	}
	print "\n";
}
