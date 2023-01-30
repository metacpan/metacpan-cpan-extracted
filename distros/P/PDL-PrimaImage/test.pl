use strict;
use warnings;
use PDL;

sub ok {
	my $no = shift ;
	my $result = shift ;
	print "not " unless $result ;
	print "ok $no\n" ;
}


BEGIN {
	print "1..4\n";
	eval 'use Prima; use PDL::PrimaImage;';
	ok('1 load module', !length $@);
}

sub convok
{
	my $no = shift;
	my ($x,$i,$x2,$i2);
	$x = shift;
	$i = PDL::PrimaImage::image($x);
	$x2 = sprintf "%s", $x;
	$i2 = sprintf "%s", PDL::PrimaImage::piddle( $i);
	$x2 =~ s/\s+//g;
	$i2 =~ s/\s+//g;
	ok( $no, $x2 eq $i2);
}

convok('2 byte', byte(
	[ 10, 111, 2, 3], [4, 115, 6, 7]
));
convok('3 rgb', float(
	[[ 10, 111, 2], [ 3, 4, 115], [6, 7, 8]],
	[[ 0, 11, 21], [ 13, 5, 115], [16, 17, 18]]
));
convok('4 complex', double(
	[[ 10.111, 2], [ 3.4, 115], [6.7, 8]],
	[[ 0.11, 21], [ 13.5, 115], [16.7, 18]]
));
