#!perl

use strict;
use warnings;

use Test::More;
use Test::DNS;

plan skip_all => 'requires AUTHOR_TESTING' unless $ENV{'AUTHOR_TESTING'};

my $dns = Test::DNS->new();

# the NS record of a domain
$dns->is_ns(
    'perl.com' => [
        ( map { "ns$_.eu.bitnames.com" } 1 .. 2 ),
        ( map { "ns$_.us.bitnames.com" } 1 .. 3 ),
    ],
);

# NS in hash
$dns->is_ns( {
    'perl.com' => [
        ( map { "ns$_.eu.bitnames.com" } 1 .. 2 ),
        ( map { "ns$_.us.bitnames.com" } 1 .. 3 ),
    ],
    'microsoft.com' => [ map { "ns$_.msft.net"        } 1 .. 5   ],
} );

done_testing();

