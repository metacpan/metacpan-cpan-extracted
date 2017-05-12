# Test working with Ext.Direct requests

package test::class;

use RPC::ExtDirect::Event;
use RPC::ExtDirect Action => 'test';

sub foo : ExtDirect(2) { [@_] }
sub bar : ExtDirect(params => ['foo', 'bar']) { shift; +{@_} }
sub qux : ExtDirect(pollHandler) {
    return (
        RPC::ExtDirect::Event->new('foo', 'blah'),
        RPC::ExtDirect::Event->new('bar', 'bleh'),
    );
}

sub meta_ordered : ExtDirect(1, metadata => { len => 1, arg => 9 }) {
    my ($class, $arg1, $meta) = @_;

    return { arg1 => $arg1, meta => $meta };
}

sub meta_named : ExtDirect(params => [], strict => !1, metadata => { params => [], strict => !1, arg => '_m' }) {
    my ($class, %arg) = @_;

    my $meta = delete $arg{_m};

    return { arg => \%arg, meta => $meta };
}

package main;

use strict;
use warnings;

use RPC::ExtDirect::Test::Util qw/ cmp_api cmp_json /;

use Test::More tests => 13;

use lib 't/lib';
use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Server::Test::Util;

my $static_dir = 't/htdocs';
my ($host, $port) = maybe_start_server( static_dir => $static_dir );

ok $port, "Got host: $host and port: $port";

my $api_uri    = "http://$host:$port/extdirectapi";
my $router_uri = "http://$host:$port/extdirectrouter";
my $poll_uri   = "http://$host:$port/extdirectevents";

my $resp = get $api_uri;

is_status   $resp, 200,'API status';
like_header $resp, 'Content-Type', qr/^application\/javascript/,
    'API content type';

my $want = <<'END_API';
Ext.app.REMOTING_API = {"actions":{"test":[{"name":"bar","params":["foo","bar"]},{"len":2,"name":"foo"},{"name":"meta_ordered","len":1,"metadata":{"len":1}},{"name":"meta_named","params":[],"strict":false,"metadata":{"params":[],"strict":false}}]},"type":"remoting","url":"/extdirectrouter"};
Ext.app.POLLING_API = {"type":"polling","url":"/extdirectevents"};
END_API

my $have = $resp->{content};

cmp_api $have, $want, "API content";

my $req = q|{"type":"rpc","tid":1,"action":"test","method":"foo",|.
          q|"data":["foo","bar"]}|;

$resp = post $router_uri, { content => $req };

is_status $resp, 200, "Ordered req status";

$have = $resp->{content};
$want = q|{"result":["test::class","foo","bar"],"type":"rpc",|.
        q|"action":"test","method":"foo","tid":1}|;

cmp_json $have, $want, "Ordered req content"
    or diag explain "Response:", $resp;

$req = q|{"type":"rpc","tid":2,"action":"test","method":"bar",|.
       q|"data":{"foo":42,"bar":"blerg"}}|;

$resp = post $router_uri, { content => $req };

is_status $resp, 200, "Named req status";

$have = $resp->{content};
$want = q|{"result":{"foo":42,"bar":"blerg"},"type":"rpc",|.
        q|"action":"test","method":"bar","tid":2}|;

cmp_json $have, $want, "Named req content"
    or diag explain "Response:", $resp;

$req = q|{"type":"rpc","tid":3,"action":"test","method":"meta_ordered",|.
       q|"data":[42],"metadata":["foo"]}|;

$resp = post $router_uri, { content => $req };

is_status $resp, 200, "Ordered meta status";

$have = $resp->{content};
$want = q|{"result":{"arg1":42,"meta":["foo"]},"type":"rpc",|.
        q|"action":"test","method":"meta_ordered","tid":3}|;

cmp_json $have, $want, "Ordered meta content"
    or diag explain "Response:", $resp;

$req = q|{"type":"rpc","tid":4,"action":"test","method":"meta_named",|.
       q|"data":{"foo":"bar"},"metadata":{"fred":"frob"}}|;

$resp = post $router_uri, { content => $req };

$have = $resp->{content};
$want = q|{"result":{"arg":{"foo":"bar"},"meta":{"fred":"frob"}},|.
        q|"type":"rpc","action":"test","method":"meta_named","tid":4}|;

cmp_json $have, $want, "Named meta content"
    or diag explain "Response:", $resp;

$resp = get $poll_uri;

is_status $resp, 200, "Poll req status";

$have = $resp->{content};
$want = q|[{"type":"event","name":"foo","data":"blah"},|.
        q|{"type":"event","name":"bar","data":"bleh"}]|;

cmp_json $have, $want, "Poll req content"
    or diag explain "Response:", $resp;

