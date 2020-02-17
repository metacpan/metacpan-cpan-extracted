#!perl -T
use Test2::V0;
use Net::DNS::Resolver::Mock;
use Net::DNS::RR;
use Data::Dumper;

plan 4;

my $res = Net::DNS::Resolver::Mock->new();

$res->zonefile_parse( 'test. 10 in a 127.0.0.1' );

my $q = $res->query( 'test.', 'a' );
ok( $q );
my @resp = $q->answer();
is( length( @resp ), 1, 'Existing record not returned');
my $rr = Net::DNS::RR->new( 'test. 10 in a 127.0.0.1' );
is( $resp[0], $rr, 'Different record returned');
$q = $res->query( 'testx.', 'a' );
ok( !$q, 'Undefined record should not be returned' );
