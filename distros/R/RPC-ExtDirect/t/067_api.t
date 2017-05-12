# Selective API publishing based on env objects

use strict;
use warnings;

use Test::More tests => 6;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Config;
use RPC::ExtDirect::API;

package RPC::ExtDirect::API::Method::Foo;

use base 'RPC::ExtDirect::API::Method';

sub get_api_definition {
    my ($self, $env) = @_;

    my $user   = 'HASH' eq ref($env) && $env->{user};
    my $action = $self->action;

    return if $user ne 'foo' && $action ne 'Foo';

    return $self->SUPER::get_api_definition($env);
}

package main;

my $test_data = eval do { local $/; <DATA>; } or die "Can't eval DATA: '$@'";

my $api_def = $test_data->{api_def};
my $tests   = $test_data->{tests};

my $config = RPC::ExtDirect::Config->new(
    debug_serialize  => 1,
    namespace        => 'myApp.Server',
    router_path      => '/router.cgi',
    poll_path        => '/poll.cgi',
    remoting_var     => 'Ext.app.REMOTE_CALL_API',
    polling_var      => 'Ext.app.REMOTE_EVENT_API',
    api_method_class => 'RPC::ExtDirect::API::Method::Foo',
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

is      $@,    '',    "anon remoting_api() eval $@";
cmp_api $have, $want, "anon remoting_api() result";

$want = shift @$tests;
$have = eval { $api->get_remoting_api( env => { user => 'foo' } ) };

is      $@,    '',    "authz remoting_api eval $@";
cmp_api $have, $want, "authz remoting_api result";

__DATA__
#line 69
{
    api_def => {
        'Foo' => {
            remote  => 1,
            methods => {
                foo_foo     => { len => 1 },
                foo_bar     => { len => 2 },
                foo_blessed => { },
                foo_baz     => { params => [qw/ foo bar baz /] },
                foo_zero    => { len => 0 },
            },
        },
        'Bar' => {
            remote  => 1,
            methods => {
                bar_bar => { len => 5 },
                bar_foo => { len => 4 },
                bar_baz => { formHandler => 1 },
            },
        },
        'Qux' => {
            remote  => 1,
            methods => {
                foo_foo => { len => 1 },
                bar_bar => { len => 5 },
                bar_foo => { len => 4 },
                bar_baz => { formHandler => 1 },
                foo_bar => { len => 2 },
                foo_baz => { params => [qw/ foo bar baz /] },
            },
        },
        'PollProvider' => {
            remote  => 1,
            methods => {
                foo => { pollHandler => 1 },
            },
        },
    },
    
    tests => [
        q~
Ext.app.REMOTE_CALL_API = {
    "actions": {
        "Foo": [
                { "len":1, "name":"foo_foo" },
                { "len":2, "name":"foo_bar" },
                { "name":"foo_blessed", "params":[], "strict":false },
                { "name":"foo_baz", "params":["foo","bar","baz"] },
                { "len":0, "name":"foo_zero" }
        ]
    },
    "namespace":"myApp.Server",
    "type":"remoting",
    "url":"/router.cgi"
};
Ext.app.REMOTE_EVENT_API = {
    "type":"polling",
    "url":"/poll.cgi"
};
        ~,
        
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
    "url":"/router.cgi"
};
Ext.app.REMOTE_EVENT_API = {
    "type":"polling",
    "url":"/poll.cgi"
};
        ~,
    ],
}
