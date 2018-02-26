#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 2;

use_ok( 'Steemit::WsClient' ) || print "Bail out!\n";


#details taken from https://steemit.com/steem/@xeroc/steem-transaction-signing-in-a-nutshell
my $steem = Steemit::WsClient->new();
my $xerox_transaction_json = <<JSON;
{
      "ref_block_num": 36029,
      "ref_block_prefix": 1164960351,
      "expiration": "2016-08-08T12:24:17",
      "operations": [["vote",
                      {"author": "xeroc",
                       "permlink": "piston",
                       "voter": "xeroc",
                       "weight": 10000}]],
      "extensions": [],
      "signatures": []
}

JSON

use Mojo::JSON qw(decode_json encode_json);

my $example_transaction_hash = decode_json ( $xerox_transaction_json );

my $expected_serialisation_result = '0000000000000000000000000000000000000000000000000000000000000000bd8c5fe26f45f179a8570100057865726f63057865726f6306706973746f6e102700';

my $created_serialisation_result  = $steem->_serialize_transaction_message( $example_transaction_hash );

is( unpack( "H*", $created_serialisation_result ), $expected_serialisation_result, "serialisation works acording to spec for transactions" );
