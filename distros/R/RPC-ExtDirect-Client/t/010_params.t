# Test params and URI handling for remote APIs

package test::class;

use RPC::ExtDirect::Event;
use RPC::ExtDirect Action => 'test';

sub foo : ExtDirect(0) { 'foo' }

sub poll : ExtDirect(pollHandler) {
    return ( RPC::ExtDirect::Event->new('foo', 'bar') )
}

package main;

use strict;
use warnings;

use Test::More tests => 12;

use RPC::ExtDirect::API;
use RPC::ExtDirect::Client;

use lib 't/lib';
use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Client::Test::Util;

# Clean up %ENV so that HTTP::Tiny does not accidentally connect to a proxy
clean_env;

# Client gets created before server can respond; this way we make sure
# the API is indeed not retrieved remotely

my $cclass = 'RPC::ExtDirect::Client';
my $aclass = 'RPC::ExtDirect::Client::API';

# This is an empty stub, which is okay for this test
my $api = RPC::ExtDirect->get_api();

my (%uris, $client);

# Proto + port
$client = eval {
    $cclass->new(
        host => 'localhost',
        port => 4884,
        proto => 'https',
        api  => $api,
    )
};

is     $@,      '',      "Constructor eval $@";
ok     $client,          "Got object";
ref_ok $client, $cclass, "Client object";

%uris = (
    api => 'https://localhost:4884/extdirectapi',
    remoting => 'https://localhost:4884/extdirectrouter',
    polling => 'https://localhost:4884/extdirectevents',
);

foreach my $type (keys %uris) {
    my $want = $uris{$type};
    my $have = $client->_get_uri($type);
    
    is $have, $want, "Got URI for type $type";
}

# Default proto + port
$client = eval {
    $cclass->new(
        host => 'localhost',
        port => 8888,
        api  => $api,
    )
};

%uris = (
    api => 'http://localhost:8888/extdirectapi',
    remoting => 'http://localhost:8888/extdirectrouter',
    polling => 'http://localhost:8888/extdirectevents',
);

foreach my $type (keys %uris) {
    my $want = $uris{$type};
    my $have = $client->_get_uri($type);
    
    is $have, $want, "Got URI for type $type";
}

# Default proto + default port
$client = eval {
    $cclass->new(
        host => 'localhost',
        api  => $api,
    )
};

%uris = (
    api => 'http://localhost/extdirectapi',
    remoting => 'http://localhost/extdirectrouter',
    polling => 'http://localhost/extdirectevents',
);

foreach my $type (keys %uris) {
    my $want = $uris{$type};
    my $have = $client->_get_uri($type);
    
    is $have, $want, "Got URI for type $type";
}
