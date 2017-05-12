# Passing relevant config options to the client side

use strict;
use warnings;

use Test::More tests => 2;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Config;

use RPC::ExtDirect::Test::Pkg::Foo;
use RPC::ExtDirect::Test::Pkg::Bar;
use RPC::ExtDirect::Test::Pkg::Qux;

use RPC::ExtDirect::API;

my $tests = eval do { local $/; <DATA>; } or die "Can't eval DATA: '$@'";

my $config = RPC::ExtDirect::Config->new(
    debug_api       => 1,
    debug_serialize => 1,
    timeout         => 42,
    max_retries     => 1,
    namespace       => 'myApp.Server',
    router_path     => '/router.cgi',
    poll_path       => '/poll.cgi',
    remoting_var    => 'Ext.app.REMOTE_CALL_API',
    no_polling      => 1,
);

my $want = shift @$tests;
my $have = eval {
    RPC::ExtDirect::API->get_remoting_api(config => $config)
};

is      $@,    '',    "API options eval $@";
cmp_api $have, $want, "API options result";

__DATA__
#line 40
[
    q~
Ext.app.REMOTE_CALL_API = {
    "actions": {
        "Bar": [
                { "len":5, "name":"bar_bar" },
                { "len":4, "name":"bar_foo" },
                { "formHandler":true, "name":"bar_baz" }
        ],
        "Foo": [
                { "len":1, "name":"foo_foo" },
                { "len":2, "name":"foo_bar" },
                { "name":"foo_blessed", "params":[], "strict":false },
                { "name":"foo_baz", "params":["foo","bar","baz"] },
                { "len":0, "name":"foo_zero" }
        ],
        "Qux": [
                { "len":1, "name":"foo_foo" },
                { "len":5, "name":"bar_bar" },
                { "len":4, "name":"bar_foo" },
                { "formHandler":true, "name":"bar_baz" },
                { "len":2, "name":"foo_bar" },
                { "name":"foo_baz", "params":["foo","bar","baz"] }
        ]
    },
    "namespace":"myApp.Server",
    "type":"remoting",
    "url":"/router.cgi",
    "timeout":42,
    "maxRetries":1
};
    ~,
]
