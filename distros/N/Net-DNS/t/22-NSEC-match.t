# $Id: 22-NSEC-match.t 1740 2019-04-04 14:45:31Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Net::DNS::RR::NSEC
		);

foreach my $package (@prerequisite) {
	next if eval "use $package; 1;";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 8;


my $owner    = 'match.example.com';
my $nxtdname = 'irrelevant';
my @typelist = qw(TYPE1 TYPE2 TYPE3);

my @args = ( $nxtdname, @typelist );

my $nsec = new Net::DNS::RR("$owner NSEC @args");


my @match = qw(
		match.example.com.
		match.EXAMPLE.com
		MATCH.example.com
		match.example.com
		);


my @nomatch = qw(
		example.com
		*.example.com
		mis.match.example.com
		mis-match.example.com
		);


foreach my $name (@match) {
	ok( $nsec->match($name), " nsec->match($name)" );
}


foreach my $name (@nomatch) {
	ok( !$nsec->match($name), "!nsec->match($name)" );
}


exit;

__END__

