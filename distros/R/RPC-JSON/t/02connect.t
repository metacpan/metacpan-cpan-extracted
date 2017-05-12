#!perl -wT

use warnings;
use strict;

use Test::More tests => 4;

use_ok("RPC::JSON");
my $jsonrpc1 = RPC::JSON->new(
    "http://rpc-json-test.theantipop.org/json.smd" );
ok($jsonrpc1, "Creating RPC::JSON object with SMD URI");

my $jsonrpc2 = RPC::JSON->new(
    smd => "http://rpc-json-test.theantipop.org/json.smd" );
ok($jsonrpc2, "Creating RPC::JSON object with hash");

my $jsonrpc3 = RPC::JSON->new({
    smd => "http://rpc-json-test.theantipop.org/json.smd" });
ok($jsonrpc3, "Creating RPC::JSON object with hash reference");

my $result = $jsonrpc3->Ping( { ping => 'pong' } );
