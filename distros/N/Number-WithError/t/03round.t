#!/usr/bin/perl -w

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			'lib',
			);
	}
}

use Test::More tests => 132;


#####################################################################

use Number::WithError qw/:all/;

my @n = (
	# input, sig digit, output before 'e', output exponent
	[ 6555070.45039773, -2, "6.55507045", 6 ],
	[ 65795926.2302157, 5,  "6.58", 7 ],
	[ 0.19100942843788, -3, "1.91", -1 ],
	[ 1234.19100942843788, -3, "1.234191", 3 ],
	[ 1234.19100942843788, 0, "1.234", 3 ],
	[ 1.234942843788, 0, "1", 0 ],
	[ 1.234942843788, 3, "0", 3 ],
	[ 0.0005234942843788, -1, "0", -1 ],
	[ 0.0005234942843788, -3, "1", -3 ],
	[ 523.4942843788, 3, "1", 3 ],
	[ 523.4942843788, 2, "5", 2 ],
	
	[ -6555070.45039773, -2, "-6.55507045", 6 ],
	[ -65795926.2302157, 5,  "-6.58", 7 ],
	[ -0.19100942843788, -3, "-1.91", -1 ],
	[ -1234.19100942843788, -3, "-1.234191", 3 ],
	[ -1234.19100942843788, 0, "-1.234", 3 ],
	[ -1.234942843788, 0, "-1", 0 ],
	[ -1.234942843788, 3, "0", 3 ],
	[ -0.0005234942843788, -1, "0", -1 ],
	[ -0.0005234942843788, -3, "-1", -3 ],
	[ -523.4942843788, 3, "-1", 3 ],
	[ -523.4942843788, 2, "-5", 2 ],
);

foreach my $n (@n) {
	my $num = Number::WithError->new($n->[0],"1e".($n->[1]+1))->number();
	ok($num =~ /^([+-]?(?:\d+|\d*\.\d+))[eE]([+-]?\d+)$/, "Number '$n->[0]' is rounded to the correct format (result: $num)");
	my $f = $1;
	my $s = $2;
	ok($f eq $n->[2]);
	ok($s == $n->[3]);
}


foreach my $n (@n) {
	my $num = Number::WithError->new_big($n->[0],"1e".($n->[1]+1))->number();
	ok($num =~ /^([+-]?(?:\d+|\d*\.\d+))[eE]([+-]?\d+)$/, "Number '$n->[0]' is rounded to the correct format (result: $num)");
	my $f = $1;
	my $s = $2;
	ok($f eq $n->[2]);
	ok($s == $n->[3]);
}
