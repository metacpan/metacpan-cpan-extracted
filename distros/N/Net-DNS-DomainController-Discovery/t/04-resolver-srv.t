#!perl -T
use Test2::V0;
use Net::DNS::Resolver::Mock;
use Net::DNS::RR;
use Data::Dumper;

plan 4;

my $res = Net::DNS::Resolver::Mock->new();

$res->zonefile_parse( '_ldap._tcp.dc._msdcs.fabrikam.com. 10 in srv 0 100 389 alpha.dc.fabrikam.com.' );

my $q = $res->query( '_ldap._tcp.dc._msdcs.fabrikam.com.', 'srv' );
ok( $q );
my @resp = $q->answer();
is( length( @resp ), 1, 'Existing record not returned');
my $rr = Net::DNS::RR->new( '_ldap._tcp.dc._msdcs.fabrikam.com. 10 in srv 0 100 389 alpha.dc.fabrikam.com.' );
is( $resp[0], $rr, 'Different record returned');
$q = $res->query( '_ldap._udp.dc._msdcs.fabrikam.com.', 'srv' );
ok( !$q, 'Undefined record should not be returned' );
