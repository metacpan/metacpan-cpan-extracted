use Test::More;
use JSON::PP;

use_ok( 'Net::LDNS' );

my $p = Net::LDNS::Packet->new( 'www.iis.se', 'A', 'IN' );
$p->answerfrom( '127.0.0.1' );
$p->timestamp( '1384423749.28615' );

my $json = JSON::PP->new->allow_blessed->convert_blessed;
my $ref  = decode_json $json->encode( $p );
is( $ref->{'Net::LDNS::Packet'}{answerfrom}, '127.0.0.1' );

my $decode = JSON::PP->new->filter_json_single_key_object(
    'Net::LDNS::Packet' => sub { is $_[0]->{answerfrom}, '127.0.0.1'; return; } );
$decode->decode( $json->encode( $p ) );

done_testing;
