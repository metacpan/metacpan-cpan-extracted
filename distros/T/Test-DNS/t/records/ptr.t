#!perl

use strict;
use warnings;

use Test::More;
use Test::DNS;

plan skip_all => 'requires AUTHOR_TESTING' unless $ENV{'AUTHOR_TESTING'};

my $dns = Test::DNS->new();

# the PTR record of an IP
$dns->is_ptr( '74.125.148.13' => 'rate-limited-proxy-74-125-148-13.google.com' );
$dns->is_ptr( '74.125.148.13' => [ 'rate-limited-proxy-74-125-148-13.google.com' ] );

# PTR in hash
$dns->is_ptr( {
    '74.125.148.13' =>   'rate-limited-proxy-74-125-148-13.google.com',
    '65.55.88.22'   => [ 'mail-pu1apc01lp0022.outbound.protection.outlook.com' ],
} );

done_testing();

