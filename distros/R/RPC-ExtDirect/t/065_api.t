# API initialization from a hashref

use strict;
use warnings;

use Test::More tests => 4;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Config;
use RPC::ExtDirect::API;

my $test_data = eval do { local $/; <DATA>; } or die "Can't eval DATA: '$@'";

my $api_def = $test_data->{api_def};
my $tests   = $test_data->{tests};

my $config = RPC::ExtDirect::Config->new(
    debug_serialize => 1,
    namespace       => 'myApp.Server',
    router_path     => '/router.cgi',
    poll_path       => '/poll.cgi',
    remoting_var    => 'Ext.app.REMOTE_CALL_API',
    polling_var     => 'Ext.app.REMOTE_EVENT_API',
    auto_connect    => 'HELL YEAH!',
);

my $api = eval {
    RPC::ExtDirect::API->new_from_hashref(
        config   => $config,
        api_href => $api_def,
    )
};

is     $@,   '', "new_from_hashref eval $@";
ref_ok $api, 'RPC::ExtDirect::API';

$api->config->debug_serialize(1);

my $want = shift @$tests;
my $have = eval { $api->get_remoting_api() };

is      $@,    '',    "remoting_api() eval $@";
cmp_api $have, $want, "remoting_api() result";

__DATA__
#line 46
{
    api_def => {
        'RPC::ExtDirect::Test::Foo' => {
            methods => {
                foo_foo     => { len => 1 },
                foo_bar     => { len => 2 },
                foo_blessed => { },
                foo_baz     => { params => [qw/ foo bar baz /] },
                foo_zero    => { len => 0 },
            },
        },
        'RPC::ExtDirect::Test::Bar' => {
            methods => {
                bar_bar => { len => 5 },
                bar_foo => { len => 4 },
                bar_baz => { formHandler => 1 },
            },
        },
        'RPC::ExtDirect::Test::Meta' => {
            methods => {
                meta0_default => {
                    len => 0,
                    metadata => { len => 1, arg => -1 },
                },
                meta0_arg => {
                    len => 0,
                    metadata => { len => 2, arg => 0, },
                },
                meta1_default => {
                    len => 1,
                    metadata => { len => 1, arg => 99, },
                },
                meta1_arg => {
                    len => 1,
                    metadata => { len => 2, arg => 0, },
                },
                meta2_default => {
                    len => 2,
                    metadata => { len => 1, arg => -1 },
                },
                meta2_arg => {
                    len => 2,
                    metadata => { len => 2, arg => 1, },
                },
                meta_named_default => {
                    params => [],
                    metadata => { len => 1, },
                },
                meta_named_arg => {
                    metadata => { len => 1, arg => 'foo' },
                },
                meta_named_strict => {
                    metadata => { params => ['foo'], },
                },
                meta_named_unstrict => {
                    metadata => { arg => '_meta', strict => !1, },
                },
            },
        },
        'RPC::ExtDirect::Test::Qux' => {
            methods => {
                foo_foo => { len => 1 },
                bar_bar => { len => 5 },
                bar_foo => { len => 4 },
                bar_baz => { formHandler => 1 },
                foo_bar => { len => 2 },
                foo_baz => { params => [qw/ foo bar baz /] },
            },
        },
        'RPC::ExtDirect::Test::PollProvider' => {
            methods => {
                foo => { pollHandler => 1 },
            },
        },
    },

    tests => [
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
        "Meta": [
                { "name":"meta0_default", "len":0, "metadata":{ "len":1 } },
                { "name":"meta0_arg", "len":0, "metadata":{ "len":2 } },
                { "name":"meta1_default", "len":1, "metadata":{ "len":1 } },
                { "name":"meta1_arg", "len":1, "metadata":{ "len":2 } },
                { "name":"meta2_default", "len":2, "metadata":{ "len":1 } },
                { "name":"meta2_arg", "len":2, "metadata":{ "len":2 } },
                { "name":"meta_named_default", "params": [], "strict":false,
                  "metadata": { "len": 1 } },
                { "name":"meta_named_arg", "params": [], "strict":false,
                  "metadata": { "len": 1 } },
                { "name":"meta_named_strict", "params": [], "strict":false,
                  "metadata": { "params": ["foo"] } },
                { "name":"meta_named_unstrict", "params": [], "strict":false,
                  "metadata": { "params": [], "strict": false } }
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
    "url":"/router.cgi"
};
Ext.direct.Manager.addProvider(Ext.app.REMOTE_CALL_API);
Ext.app.REMOTE_EVENT_API = {
    "type":"polling",
    "url":"/poll.cgi"
};
Ext.direct.Manager.addProvider(Ext.app.REMOTE_EVENT_API);
        ~,
    ],
}
