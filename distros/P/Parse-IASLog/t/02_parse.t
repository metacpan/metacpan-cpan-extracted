use strict;
use warnings;
use Test::More tests => 17;

BEGIN { use_ok('Parse::IASLog') };

my $original = '10.10.10.10,client,06/04/1999,14:42:19,IAS,CLIENTCOMP,6,2,7,1,5,9,61,5,64,1,65,1,31,1,4136,1,4142,0';

# Object Interface
my $parser = Parse::IASLog->new();
isa_ok($parser,'Parse::IASLog');
my $record1 = $parser->parse( $original ) or die;

is( $record1->{'NAS-IP-Address'}, '10.10.10.10', 'NAS-IP-Address' );
is( $record1->{'User-Name'}, 'client', 'User-Name' );
is( $record1->{'Record-Date'}, '06/04/1999', 'Record-Date' );
is( $record1->{'Record-Time'}, '14:42:19', 'Record-Time' );
is( $record1->{'Service-Name'}, 'IAS', 'Service-Name' );
is( $record1->{'Computer-Name'}, 'CLIENTCOMP', 'Computer-Name' );

is( $record1->{'NAS-Port-Type'}, 'Virtual (VPN)', 'NAS-Port-Type' );
is( $record1->{'Service-Type'}, 'Framed', 'Service-Type' );
is( $record1->{'Tunnel-Medium-Type'}, 'IP (IP version 4)', 'Tunnel-Medium-Type' );
is( $record1->{'Tunnel-Type'}, 'Point-to-Point Tunneling Protocol (PPTP)', 'Tunnel-Type' );
is( $record1->{'Framed-Protocol'}, 'PPP', 'Framed-Protocol' );
is( $record1->{'NAS-Port'}, '9', 'NAS-Port' );
is( $record1->{'Calling-Station-ID'}, '1', 'Calling-Station-ID' );

is( $record1->{'Packet-Type'}, 'Access-Request', 'Packet-Type' );
is( $record1->{'Reason-Code'}, 'Success', 'Reason-Code' );
