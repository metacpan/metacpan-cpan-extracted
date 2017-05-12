#!perl -T

use utf8;
use Test::More tests => 3;
use Net::Domain::ES::ccTLD;

my %tests = (
    mx => 'México',
    us => 'Estados Unidos',
    nl => 'Países Bajos'
);

while(my($cc, $country) = each %tests) {
    is(
        find_name_by_cctld( $cc ),
        $country,
        "$cc => $country"
    )
}
