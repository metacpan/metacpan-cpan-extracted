# $Id: 51-DS-SHA1.t 1352 2015-06-02 08:13:13Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Digest::SHA
		MIME::Base64
		Net::DNS::RR::KEY
		Net::DNS::RR::DS
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 3;


# Simple known-answer tests based upon the examples given in RFC3658, section 2.7

my $key = new Net::DNS::RR <<'END';
dskey.example.	IN	KEY	256 3 1 (
	AQPwHb4UL1U9RHaU8qP+Ts5bVOU1s7fYbj2b3CCbzNdj
	4+/ECd18yKiyUQqKqQFWW5T3iVc8SJOKnueJHt/Jb/wt
	) ; key id = 28668
END

my $ds = new Net::DNS::RR <<'END';
dskey.example.	IN	DS	28668 1 1 (
	49fd46e6c4b45c55d4ac69cbd3cd34ac1afe51de
	;xidez-ticuv-kicur-galah-hehyp-sopys-roges-titap-sakoz-vygat-vyxox
	)
END


my $test = create Net::DNS::RR::DS( $key, digtype => 'SHA1', );

is( $test->string, $ds->string, 'created DS matches RFC3658 example DS' );

ok( $test->verify($key), 'created DS verifies RFC3658 example KEY' );

ok( $ds->verify($key), 'RFC3658 example DS verifies example KEY' );

$test->print;

__END__


