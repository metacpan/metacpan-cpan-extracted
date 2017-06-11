#!/usr/bin/env perl

use strict;
use warnings;

use JSON;

# Mojolicious app for testing
package WebsocketProxy;

use Mojo::Base 'Mojolicious';

use MojoX::JSON::RPC::Service;

sub startup {
    my $self = shift;

    $self->secrets(['Testing!']);

    $self->plugin(
        'web_socket_proxy',
        actions => [
            ['some_action'],
            ['some_action1', {auth_needed        => 1}],
            ['some_action2', {instead_of_forward => \&main::instead_of_forward}],
            ['some_action3', {before_forward     => \&main::some_action3}],
            ['some_action4', {rpc_response_cb    => \&main::some_action4}],
            [
                'some_action5',
                {
                    after_got_rpc_response => \&main::some_action51,
                }
            ],
            ['some_action6', {stash_params => [qw/ stashed_data /]}],
            ['some_action7', {response     => \&main::some_action7}],
        ],
        before_forward           => \&main::before_forward,
        before_send_api_response => \&main::add_debug,
        base_path                => '/api',
        url                      => 'http://rpc-host.com:8080/',
    );
}

# Back to tests
package main;

use Test::More;
use Test::Mojo;
use Test::MockModule;
use Test::MockObject;

# Mocking RPC client to catch RPC calls
my ($url, $call_params, $fake_rpc_response, $fake_rpc_client, $rpc_client_mock, $rpc_response);
$rpc_response = {ok => 1};
$fake_rpc_response = Test::MockObject->new();
$fake_rpc_response->mock('result',   sub { $rpc_response });
$fake_rpc_response->mock('is_error', sub { '' });
$fake_rpc_client = Test::MockObject->new();
$fake_rpc_client->mock('call', sub { shift; $url = $_[0]; $call_params = $_[1]; return $_[2]->($fake_rpc_response) });
$rpc_client_mock = Test::MockModule->new('MojoX::JSON::RPC::Client');
$rpc_client_mock->mock('new', sub { return $fake_rpc_client });

# before_forward hook
my $authorized = 1;

sub before_forward {
    my ($c, $req_storage) = @_;
    return $c->wsp_error('error', 'AuthError', 'Auth needed.')
        if $req_storage->{auth_needed} && !$authorized;
    return;
}

sub add_debug {
    my ($c, $req_storage, $api_response) = @_;
    $api_response->{debug} = $req_storage->{debug_value} || 1;
    return;
}

# Tests
my $t = Test::Mojo->new('WebsocketProxy');
my $res;

$t->websocket_ok('/api' => {});

$t = $t->send_ok({json => {some_action => 1}})->message_ok;
$res = decode_json($t->message->[1]);

is $url, 'http://rpc-host.com:8080/some_action', 'It should use url + method';
is $call_params->{method}, 'some_action', 'It should use method from actions';
ok $call_params->{id}, 'It should generate call id';
is_deeply $call_params->{params}->{args}, {some_action => 1}, 'It should forward message params';
is_deeply $res,
    {
    'some_action' => {'ok' => 1},
    'debug'       => 1,
    'msg_type'    => 'some_action'
    },
    'It should return formating response';

$t = $t->send_ok({json => {not_exists_action => 1}})->message_ok;
$res = decode_json($t->message->[1]);
is_deeply $res,
    {
    'error' => {
        'code'    => 'UnrecognisedRequest',
        'message' => 'Unrecognised request'
    },
    'debug'    => 1,
    'msg_type' => 'error'
    },
    'It should return error response if action does not exist';

$t = $t->send_ok({json => 'not_json'})->message_ok;
$res = decode_json($t->message->[1]);
is_deeply $res,
    {
    'error' => {
        'code'    => 'BadRequest',
        'message' => 'The application sent an invalid request.'
    },
    'debug'    => 1,
    'msg_type' => 'error'
    },
    'It should return error response if bad request';

$t = $t->send_ok({json => {some_action1 => 1}})->message_ok;
$res = decode_json($t->message->[1]);
ok $res->{some_action1}, 'Should return success';
ok $res->{debug},        'Should add debug param';

$authorized = '';
$url        = '';
$t          = $t->send_ok({json => {some_action1 => 1}})->message_ok;
$res        = decode_json($t->message->[1]);
is $res->{error}->{code}, 'AuthError', 'It should return before_forward response';
ok !$url, 'It should not call RPC if before_forward returns anything';

sub instead_of_forward {
    shift->call_rpc({
        args     => {param => 1},
        method   => 'some_diff_method',
        msg_type => 'some_action2',
    });
}

$t = $t->send_ok({json => {some_action2 => 1}})->message_ok;
$res = decode_json($t->message->[1]);
ok $res->{some_action2}, 'Should return success';
is $res->{msg_type}, 'some_action2', 'Should use custom msg_type';

sub some_action3 {
    return {custom_result => 1};
}

$t = $t->send_ok({json => {some_action3 => 1}})->message_ok;
$res = decode_json($t->message->[1]);
is $res->{custom_result}, 1, 'Should return success';
ok $res->{debug}, 'Should add debug param';

sub some_action4 {
    my ($c, $args, $rpc_response) = @_;
    return {custom_result => 2};
}

$t = $t->send_ok({json => {some_action4 => 1}})->message_ok;
$res = decode_json($t->message->[1]);
is $res->{custom_result}, 2, 'Should return success';
ok $res->{debug}, 'Should add debug param';

sub some_action51 {
    my ($c, $req_storage, $rps_response) = @_;
    $req_storage->{debug_value} = 3;
    return;
}

$t = $t->send_ok({json => {some_action5 => 1}})->message_ok;
$res = decode_json($t->message->[1]);
is $res->{debug}, 3, 'You can use request storage to share data between hooks';

$rpc_response = {
    ok    => 1,
    stash => {stashed_data => 1}};
$t = $t->send_ok({json => {some_action6 => 1}})->message_ok;
$t = $t->send_ok({json => {some_action6 => 1}})->message_ok;
is $call_params->{params}->{stashed_data}, 1, 'You can send data from Mojolicious stash to RPC service';

sub some_action7 {
    my ($rpc_response, $api_response, $req_storage) = @_;
    return {
        my_response     => $rpc_response,
        some_other_data => 1
    };
}

$rpc_response = {status => 1};
$t = $t->send_ok({json => {some_action7 => 1}})->message_ok;
$res = decode_json($t->message->[1]);
is $res->{my_response}->{status}, 1, 'It should return custom answer';
is $res->{my_response}->{status}, 1, 'It should return custom answer';

done_testing();
