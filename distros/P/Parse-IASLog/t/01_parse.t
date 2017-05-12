use strict;
use warnings;
use Test::More tests => 16;

BEGIN { use_ok('Parse::IASLog') };

my $original = '10.10.10.10,client,06/04/1999,14:42:19,IAS,CLIENTCOMP,6,2,7,1,5,9,61,5,64,1,65,1,31,1,4136,1,4142,0';

# Function Interface

my $record1 = parse_ias( $original, enumerate => 0 ) or die;

is( $record1->{'NAS-IP-Address'}, '10.10.10.10', 'NAS-IP-Address' );
is( $record1->{'User-Name'}, 'client', 'User-Name' );
is( $record1->{'Record-Date'}, '06/04/1999', 'Record-Date' );
is( $record1->{'Record-Time'}, '14:42:19', 'Record-Time' );
is( $record1->{'Service-Name'}, 'IAS', 'Service-Name' );
is( $record1->{'Computer-Name'}, 'CLIENTCOMP', 'Computer-Name' );

is( $record1->{'NAS-Port-Type'}, '5', 'NAS-Port-Type' );
is( $record1->{'Service-Type'}, '2', 'Service-Type' );
is( $record1->{'Tunnel-Medium-Type'}, '1', 'Tunnel-Medium-Type' );
is( $record1->{'Tunnel-Type'}, '1', 'Tunnel-Type' );
is( $record1->{'Framed-Protocol'}, '1', 'Framed-Protocol' );
is( $record1->{'NAS-Port'}, '9', 'NAS-Port' );
is( $record1->{'Calling-Station-ID'}, '1', 'Calling-Station-ID' );

is( $record1->{'Packet-Type'}, '1', 'Packet-Type' );
is( $record1->{'Reason-Code'}, '0', 'Reason-Code' );
