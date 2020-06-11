#!perl

use strict;
use warnings;

use Test::More tests => 9;
use Net::Whois::IANA;

my $iana = Net::Whois::IANA->new;
my $ip   = '193.0.0.135';

$iana->whois_query( -ip => $ip, -whois => 'ripe' );

isa_ok $iana, 'Net::Whois::IANA';

is( $iana->country(), 'NL',       'country' );
is( $iana->netname(), 'RIPE-NCC', 'netname' );
like( $iana->descr(), qr{RIPE Network}, "descr" );
is( $iana->desc(), $iana->descr(), "desc - backward compatible" );
is( $iana->status(), 'ASSIGNED PA', 'status' );
is( $iana->source(), 'RIPE RIPE',   'source' );
is( $iana->server(), 'RIPE',        'server' );
ok( $iana->inetnum(), 'inetnum' );

#is( $iana->inet6num(), 'NL', 'inet6num' );
