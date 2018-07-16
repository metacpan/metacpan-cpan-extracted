# $Id: 31-NSEC3-base32.t 1681 2018-05-28 12:57:49Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Net::DNS::RR::NSEC3
		);

foreach my $package (@prerequisite) {
	next if eval "use $package; 1";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 30;


my %testcase = (
	chr(85) x 1  => 'ak',
	chr(85) x 2  => 'alag',
	chr(85) x 3  => 'alala',
	chr(85) x 4  => 'alalal8',
	chr(85) x 5  => 'alalalal',
	chr(85) x 6  => 'alalalalak',
	chr(85) x 7  => 'alalalalalag',
	chr(85) x 8  => 'alalalalalala',
	chr(85) x 9  => 'alalalalalalal8',
	chr(85) x 10 => 'alalalalalalalal',
	);


foreach my $binary ( sort keys %testcase ) {
	my $base32 = $testcase{$binary};
	my $encode = Net::DNS::RR::NSEC3::_encode_base32hex($binary);
	my $decode = Net::DNS::RR::NSEC3::_decode_base32hex($base32);
	is( $encode,	     $base32,	      'base32hex encode correct' );
	is( length($decode), length($binary), 'decode length correct' );
	ok( $decode eq $binary, 'base32hex decode correct' );
}


exit;

__END__


