use strict;
use warnings;

use lib 'lib';

use Test::More;

use JSON::XS;
use Sailthru::Client;

#
# test the extraction / signature / hashing functions in Sailthru::Client
#

my $api_key = 'abcdef1234567890abcdef1234567890';
my $secret  = '00001111222233334444555566667777';
my $sc      = Sailthru::Client->new( $api_key, $secret );

my $sig;
my $args = {
    email         => 'test@example.com',
    format        => 'xml',
    'vars[myvar]' => 'TestValue',
    optout        => 0,
    api_key       => $api_key,
};

$sig = $sc->_get_signature_hash( $args, $secret );
is( $sig, 'b0c1ba5e661d155a940da08ed240cfb9', 'get_signature_hash with multiple arguments' );

$args = {
    api_key => $api_key,
    format  => 'json',
    json    => encode_json( { email => 'stevesanbeg@buzzfeed.com', lists => { Test => 1 } } ),
};

$sig = $sc->_get_signature_hash( $args, $secret );
is( $sig, '62c9f19c053146634d94d531e2492438', 'get_signature_hash with JSON' );

# data for testing extraction and signature hash functions
$secret = '123456';
my $simple_data = {
    'unix'    => [ 'Linux', 'Mac', 'Solaris' ],
    'windows' => 'None'
};
my $simple_json = encode_json($simple_data);
my $simple_args = {
    api_key => 'foobarbaz',
    format  => 'json',
    json    => $simple_json
};
my @simple_values = sort 'foobarbaz', 'json', $simple_json;

done_testing;
