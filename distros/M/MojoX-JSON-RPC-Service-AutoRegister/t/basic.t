#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;

use lib join '/', File::Spec->splitdir( dirname(__FILE__) ), 'lib';
use lib join '/', File::Spec->splitdir( dirname(__FILE__) ), '..', 'lib';

#-------------------------------------------------------------------

# Define custom service
package MyService;

use Mojo::Base 'MojoX::JSON::RPC::Service::AutoRegister';

sub multiply {
    my ( $self, $tx, $dispatcher, @params ) = @_;
    my $m = 1;
    $m *= $_ for @params;

    return $m;
}

sub echo {
    my ( $self, $tx, $dispatcher, @params ) = @_;

    return $params[0];
}

sub echo_key {
    my ( $self, $tx, $dispatcher, $param ) = @_;

    return exists $param->{key} ? $param->{key} : '?';
}

sub register {
    my ( $self, $tx, $dispatcher ) = @_;
    return 'register can be used';
}

sub rpc_register {
    my ( $self, $tx, $dispatcher ) = @_;
    return 'register can be used';
}

sub _test_register {
    my ( $self, $tx, $dispatcher ) = @_;
    return 'register can be used';
}

sub suffix_register {
    my ( $self, $tx, $dispatcher ) = @_;
    return 'register can be used';
}

sub _rpcs {
    my ( $self, $tx, $dispatcher ) = @_;
    return '_rpcs can be used';
}

sub substract {
    my ( $self, $tx, $dispatcher, $res, @params ) = @_;
    $res = 0 if !defined $res;
    $res -= $_ for @params;
    return $res;
}

sub update {
    my ( $self, $tx, $dispatcher, @params ) = @_;

    # notification only

    return;
}

sub foobar {
    my ( $self, $tx, $dispatcher ) = @_;

    # notification only

    return;
}

__PACKAGE__->register_rpc_method_names(
    'multiply', 'echo',      'echo_key', 'register',
    '_rpcs',    'substract', 'update',   'foobar'
);

__PACKAGE__->register_rpc;
__PACKAGE__->register_rpc_regex(qr/^_test/);
__PACKAGE__->register_rpc_suffix("suffix");

#-------------------------------------------------------------------

# Mojolicious app for testing
package MojoxJsonRpc;

use Mojo::Base 'Mojolicious';

use MojoX::JSON::RPC::Service::AutoRegister;

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->secrets( ['Testing!'] );

    # Load our test plugin
    my $svc = MojoX::JSON::RPC::Service::AutoRegister->new->register(
        'sum',
        sub {
            my @params = @_;
            my $sum    = 0;
            $sum += $_ for @params;
            return $sum;
        }
        )->register(
        'remote_address',
        sub {
            my $tx = shift;
            return $tx->remote_address;
        },
        { with_mojo_tx => 1 }
        )->register(
        'substract',
        sub {
            my $params = shift;

            return $params->{minuend} - $params->{subtrahend};
        },
        )->register(
        'subtract',
        sub {
            my ( $res, @params ) = @_;
            $res = 0 if !defined $res;
            $res -= $_ for @params;
            return $res;
        },
        )->register(
        'notify_hello',
        sub {
            return;
        }
        )->register(
        'notify_sum',
        sub {
            return;
        }
        )->register(
        'get_data',
        sub {
            return [ 'hello', 5 ];
        }
        )->register(
        'test_with_self',
        sub {
            my $dispatcher = shift;
            return ref $dispatcher;
        },
        { with_self => 1 }
        )->register(
        'test_with_mojo_tx_and_self',
        sub {
            my $tx         = shift;
            my $dispatcher = shift;
            return [ ref $tx, ref $dispatcher ];
        },
        { with_mojo_tx => 1, with_self => 1 }
        )->register(
        'test_with_all',
        sub {
            my $svc        = shift;
            my $tx         = shift;
            my $dispatcher = shift;
            return [ ref $svc, ref $tx, ref $dispatcher ];
        },
        { with_svc_obj => 1, with_mojo_tx => 1, with_self => 1 }
        );

    # register multiple services
    $self->plugin(
        'json_rpc_dispatcher',
        services => {
            '/jsonrpc'  => $svc,
            '/jsonrpc2' => MyService->new
        }
    );
}

#-------------------------------------------------------------------

# Back to tests
package main;

use TestUts;

use Test::More tests => 39;
use Test::Mojo;

use_ok 'MojoX::JSON::RPC::Service::AutoRegister';
use_ok 'MojoX::JSON::RPC::Client';

my $t = Test::Mojo->new('MojoxJsonRpc');
my $client = MojoX::JSON::RPC::Client->new( ua => $t->ua );
my $res;

TestUts::test_call(
    $client,
    '/jsonrpc',
    {   id     => 1,
        method => 'sum',
        params => [ 17, 25 ]
    },
    {   result => 42,
        id     => 1
    },
    'sum 1'
);

# Test second service url
TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => 'multiply',
        params => [ 2, 3 ]
    },
    {   result => 6,
        id     => 2
    },
    'multiply 1'
);

# Can call register which is also defined in MojoX::JSON::RPC::Service::AutoRegister
TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => 'register',
    },
    {   result => 'register can be used',
        id     => 2
    },
    'register 1'
);

TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => 'rpc_register',
    },
    {   result => 'register can be used',
        id     => 2
    },
    'rpc_register 1'
);

TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => '_test_register',
    },
    {   result => 'register can be used',
        id     => 2
    },
    '_test_register 1 with regex'
);

TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => 'suffix_register',
    },
    {   result => 'register can be used',
        id     => 2
    },
    'suffix_register 1 with regex'
);

TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => 'echo',
        params => ['HEEEEEEEEEEEEEEEEELLLLLLLLLLLLLLLOOOOOOOOOOO!']
    },
    {   result => 'HEEEEEEEEEEEEEEEEELLLLLLLLLLLLLLLOOOOOOOOOOO!',
        id     => 2
    },
    'echo 1'
);

# params must be array!
TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => 'echo',
        params => 'HEEEEEEEEEEEEEEEEELLLLLLLLLLLLLLLOOOOOOOOOOO!'
    },
    {   error => {
            code    => -32602,
            message => 'Invalid params.',
            data =>
                'NOT array or hash: HEEEEEEEEEEEEEEEEELLLLLLLLLLLLLLLOOOOOOOOOOO!'
        }
    },
    'echo 2'
);

TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => 'echo',
        params => [ 'a' x 32768 ]
    },
    {   result => 'a' x 32768,
        id     => 2
    },
    'echo 3'
);

# Can call _rpcs which is an attribute of MojoX::JSON::RPC::Service::AutoRegister
TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => '_rpcs',
    },
    { result => '_rpcs can be used', },
    '_rpcs 1'
);

# Test rpc call that get tx added on server side.
TestUts::test_call(
    $client,
    '/jsonrpc',
    {   id     => 2,
        method => 'remote_address',
    },
    { result => '127.0.0.1', },
    'remote_address 1'
);

# Test hash param
TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => 'echo_key',
        params => { key => 'HEEEEEEEEEEEEEEEEELLLLLLLLLLLLLLLOOOOOOOOOOO!' }
    },
    { result => 'HEEEEEEEEEEEEEEEEELLLLLLLLLLLLLLLOOOOOOOOOOO!', },
    'echo_key 1'
);

# GET test
TestUts::test_call(
    $client, '/jsonrpc?method=sum;params=[2,3,5];id=1',
    undef, { results => 10 },
    'GET sum 1'
);

TestUts::test_call(
    $client,
    '/jsonrpc?',
    undef,
    {   error => {
            code    => -32600,
            message => 'Invalid Request.'
        }
    },
    'GET no method'
);

# Test client proxy

my $proxy = $client->prepare(
    '/jsonrpc'  => 'sum',
    '/jsonrpc2' => [ 'multiply', 'echo' ]
);

is( $proxy->sum( 1, 2 ), 3, 'proxy sum 1' );
is( $proxy->multiply( 1, 2, 3 ), 6, 'proxy multiply 1' );
is( $proxy->echo('Testing 1 2 3'), 'Testing 1 2 3', 'proxy echo 1' );

### Test non blocking

my $loop_count = 1;

my $nb_test1;
my $nb_test2;

$client->call(
    '/jsonrpc',
    {   id     => 2,
        method => 'sum',
        params => [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
    },
    sub {
        my $res = pop;

        $nb_test1 = $res->result;
        if ( $loop_count-- == 0 ) { Mojo::IOLoop->stop; }
    }
);

$client->call(
    '/jsonrpc2',
    {   id     => 2,
        method => 'echo',
        params => ['..................................']
    },
    sub {
        my $res = pop;

        $nb_test2 = $res->result;
        if ( $loop_count-- == 0 ) { Mojo::IOLoop->stop; }
    }
);
Mojo::IOLoop->start;

is( $nb_test1, 45, 'Non blocking 1' );
is( $nb_test2, '..................................', 'Non blocking 2' );

######## Some extra tests from spec

#rpc call with positional parameters:
#--> {"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}
#<-- {"jsonrpc": "2.0", "result": 19, "id": 1}

TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 1,
        method => 'substract',
        params => [ 42, 23 ]
    },
    {   result => 19,
        id     => 1
    },
    'rpc call with positional parameters 1'
);

#--> {"jsonrpc": "2.0", "method": "subtract", "params": [23, 42], "id": 2}
#<-- {"jsonrpc": "2.0", "result": -19, "id": 2}
TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   id     => 2,
        method => 'substract',
        params => [ 23, 42 ]
    },
    {   id     => 2,
        result => -19,
    },
    'rpc call with positional parameters 2'
);

#rpc call with named parameters:
#--> {"jsonrpc": "2.0", "method": "subtract", "params": {"subtrahend": 23, "minuend": 42}, "id": 3}
#<-- {"jsonrpc": "2.0", "result": 19, "id": 3}

TestUts::test_call(
    $client,
    '/jsonrpc',
    {   id     => 3,
        method => 'substract',
        params => {
            minuend    => 42,
            subtrahend => 23,
        }
    },
    {   id     => 3,
        result => 19,
    },
    'rpc call with named parameters 1'
);

#--> {"jsonrpc": "2.0", "method": "subtract", "params": {"minuend": 42, "subtrahend": 23}, "id": 4}
#<-- {"jsonrpc": "2.0", "result": 19, "id": 4}

TestUts::test_call(
    $client,
    '/jsonrpc',
    {   id     => 4,
        method => 'substract',
        params => {
            minuend    => 23,
            subtrahend => 42,
        }
    },
    {   id     => 4,
        result => -19,
    },
    'rpc call with named parameters 2'
);

#a Notification:
#--> {"jsonrpc": "2.0", "method": "update", "params": [1,2,3,4,5]}

TestUts::test_call(
    $client,
    '/jsonrpc2',
    {   method => 'update',
        params => [ 1, 2, 3, 4, 5 ]
    },
    {},
    'a Notification 1'
);

#--> {"jsonrpc": "2.0", "method": "foobar"}
TestUts::test_call( $client, '/jsonrpc2', { method => 'foobar', },
    {}, 'a Notification 2' );

#rpc call of non-existent method:
#--> {"jsonrpc": "2.0", "method": "foobar", "id": "1"}
#<-- {"jsonrpc": "2.0", "error": {"code": -32601, "message": "Procedure not found."}, "id": "1"}
TestUts::test_call(
    $client,
    '/jsonrpc',
    {   id     => 1,
        method => 'foobar'
    },
    {   error => {
            code    => -32601,
            message => 'Method not found.'
        },
        id => 1
    },
    'rpc call of non-existent method'
);

#rpc call with invalid JSON:
#--> {"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]
#<-- {"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error."}, "id": null}
TestUts::test_call(
    $client,
    '/jsonrpc',
    q|{"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]|,
    {   error => {
            code    => -32700,
            message => 'Parse error.'
        },
        id => undef
    },
    'rpc call with invalid JSON'
);

#rpc call with invalid Request object:
#--> {"jsonrpc": "2.0", "method": 1, "params": "bar"}
#<-- {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request."}, "id": null}
TestUts::test_call(
    $client,
    '/jsonrpc',
    {   id     => 1,
        method => 1,
        params => 'bar'
    },
    {   error => {
            code    => -32600,
            message => 'Invalid Request.'
        },
        id => undef
    },
    'rpc call with invalid Request object'
);

#rpc call Batch, invalid JSON:
#--> [ {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},{"jsonrpc": "2.0", "method" ]
#<-- {"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error."}, "id": null}
TestUts::test_call(
    $client,
    '/jsonrpc',
    q|[ {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},{"jsonrpc": "2.0", "method" ]|,
    {   error => {
            code    => -32700,
            message => 'Parse error.'
        },
        id => undef
    },
    'rpc call Batch, invalid JSON'
);

#rpc call with an empty Array:
#--> []
#<-- {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request."}, "id": null}

TestUts::test_call(
    $client,
    '/jsonrpc',
    q|[]|,
    {   error => {
            code    => -32600,
            message => 'Invalid Request.'
        },
        id => undef
    },
    'rpc call with an empty Array'
);

#rpc call with an invalid Batch (but not empty):
#--> [1]
#<-- [
#        {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request."}, "id": null}
#    ]
TestUts::test_call(
    $client,
    '/jsonrpc',
    q|[1]|,
    {   error => {
            code    => -32600,
            message => 'Invalid Request.'
        },
        id => undef
    },
    'rpc call with an invalid Batch (but not empty)'
);

#rpc call with invalid Batch:
#--> [1,2,3]
#<-- [
#        {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request."}, "id": null},
#        {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request."}, "id": null},
#        {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request."}, "id": null}
#    ]
TestUts::test_call(
    $client,
    '/jsonrpc',
    q|[1,2,3]|,
    [   {   error => {
                code    => -32600,
                message => 'Invalid Request.'
            },
            id => undef
        },
        {   error => {
                code    => -32600,
                message => 'Invalid Request.'
            },
            id => undef
        },
        {   error => {
                code    => -32600,
                message => 'Invalid Request.'
            },
            id => undef
        },
    ],
    'rpc call with an invalid Batch'
);

#rpc call Batch:
#--> [
#        {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
#        {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]},
#        {"jsonrpc": "2.0", "method": "subtract", "params": [42,23], "id": "2"},
#        {"foo": "boo"},
#        {"jsonrpc": "2.0", "method": "foo.get", "params": {"name": "myself"}, "id": "5"},
#        {"jsonrpc": "2.0", "method": "get_data", "id": "9"}
#    ]
#<-- [
#        {"jsonrpc": "2.0", "result": 7, "id": "1"},
#        {"jsonrpc": "2.0", "result": 19, "id": "2"},
#        {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request."}, "id": null},
#        {"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found."}, "id": "5"},
#        {"jsonrpc": "2.0", "result": ["hello", 5], "id": "9"}
#    ]

TestUts::test_call(
    $client,
    '/jsonrpc',
    [   { method => 'sum',          params => [ 1, 2, 4 ], id => '1' },
        { method => 'notify_hello', params => [7] },
        { method => 'subtract', params => [ 42, 23 ], id => '2' },
        { foo    => 'boo' },
        {   method => 'foo.get',
            params => { name => 'myself' },
            id     => '5'
        },
        { method => 'get_data', id => '9' }
    ],
    [   {   result => 7,
            id     => 1
        },
        {   result => 19,
            id     => 2
        },
        {   error => {
                code    => -32600,
                message => 'Invalid Request.'
            },
            id => undef
        },
        {   error => {
                code    => -32601,
                message => 'Method not found.'
            },
            id => 5
        },
        {   result => [ 'hello', 5 ],
            id     => 9
        },
    ],
    'rpc call Batch'
);

#rpc call Batch (all notifications):
#--> [
#        {"jsonrpc": "2.0", "method": "notify_sum", "params": [1,2,4]},
#        {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]},
#    ]
#<-- //Nothing is returned for all notification batches
TestUts::test_call(
    $client,
    '/jsonrpc',
    [   { method => 'notify_sum',   params => [ 1, 2, 4 ] },
        { method => 'notify_hello', params => [7] },
    ],
    {},
    'rpc call Batch (all notifications)'
);

# Test with_self option in Dispatcher
TestUts::test_call(
    $client,
    '/jsonrpc',
    [ { id => 1, method => 'test_with_self', params => [] } ],
    {   id     => 1,
        result => 'MojoX::JSON::RPC::Dispatcher',
    },
    'test with_self'
);

TestUts::test_call(
    $client,
    '/jsonrpc',
    [ { id => 2, method => 'test_with_mojo_tx_and_self', params => [] } ],
    {   id => 2,
        result =>
            [ 'Mojo::Transaction::HTTP', 'MojoX::JSON::RPC::Dispatcher' ]
    },
    'test with_mojo_tx + with_self'
);

TestUts::test_call(
    $client,
    '/jsonrpc',
    [ { id => 3, method => 'test_with_all', params => [] } ],
    {   id     => 3,
        result => [
            'MojoX::JSON::RPC::Service::AutoRegister', 'Mojo::Transaction::HTTP',
            'MojoX::JSON::RPC::Dispatcher'
        ]
    },
    'test with_svc_obj + with_mojo_tx + with_self'
);

1;
