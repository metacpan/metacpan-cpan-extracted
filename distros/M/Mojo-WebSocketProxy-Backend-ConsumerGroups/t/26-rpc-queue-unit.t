use strict;
use warnings;

use Test::More;
use Mojo::WebSocketProxy::Backend::ConsumerGroups;
use Test::MockObject;
use Test::MockModule;
use Test::Fatal;

subtest 'Subscribe for new messaging' => sub {
    my $redis           = Test::MockObject->new();
    my $was_subscribed  = 0;
    my $callback_setted = 0;
    $redis->mock(subscribe => sub { $was_subscribed++; pop->(); return shift; });
    $redis->mock(on => sub { $callback_setted++; pop->($redis, '{"message_id": "msg_id_123"}') });

    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(redis => $redis);

    $cg_backend->wait_for_messages();
    is $was_subscribed, 1, 'Subscribe for new messages';

    $cg_backend->wait_for_messages();
    is $was_subscribed, 1, 'Subscribe for new messages exactly once';

    is $callback_setted, 1, 'Callback for new messages is setted';
};

subtest 'Response handling' => sub {
    my $redis      = Test::MockObject->new();
    my $cb_counter = 0;
    $redis->mock(subscribe => sub { pop->();       return shift; });
    $redis->mock(on        => sub { $cb_counter++; pop->($redis, '{"message_id": "msg_id_123", "response": "any"}') });

    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(redis => $redis);
    my $f          = $cg_backend->pending_requests->{msg_id_123} = $cg_backend->loop->new_future;

    $cg_backend->wait_for_messages();
    is $cb_counter, 1, 'On messages call back was called';
    ok $f->is_done, 'Request marked as ready';

    my $resp = Future->wait_any($f, $cg_backend->loop->timeout_future(after => 1))->get;
    is_deeply $resp,
        {
        message_id => 'msg_id_123',
        response   => 'any'
        },
        'Got rpc result';
    is_deeply $cg_backend->pending_requests, {}, 'Message was deleted from pending requests';

    #Triggering without pending messages;
    delete $cg_backend->{already_waiting};
    $cg_backend->wait_for_messages();
    is $cb_counter, 2, 'On messages call back was called';

    is_deeply $cg_backend->pending_requests, {}, 'Pending requests should be empty';
};

subtest whoami => sub {
    my $rpc_backend1 = Mojo::WebSocketProxy::Backend::ConsumerGroups->new();
    my $rpc_backend2 = Mojo::WebSocketProxy::Backend::ConsumerGroups->new();

    my $rpc_id1 = $rpc_backend1->whoami;
    ok $rpc_id1, 'Got rpc id';

    is $rpc_id1, $rpc_backend1->whoami, 'Id will be unchanged for rpc instance';

    my $rpc_id2 = $rpc_backend2->whoami;
    ok $rpc_id2, 'Got rpc id';

    is $rpc_id1, $rpc_backend1->whoami, 'Id will be unchanged for rpc instance';
    is $rpc_id2, $rpc_backend2->whoami, 'Id will be unchanged for rpc instance';

    isnt $rpc_id1, $rpc_id2, 'Id is uniq';
};

subtest _send_request => sub {
    my $redis = Test::MockObject->new();
    $redis->mock(_execute => sub { pop->(undef, 'test error') });

    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(redis => $redis);
    my $err        = exception { $cg_backend->_send_request([])->get };

    like $err, qr{^test error}, 'Got correct error';

    $redis->mock(_execute => sub { pop->() });

    my $req_future = $cg_backend->_send_request([]);

    eval { $req_future->get };

    ok $req_future->is_done, 'Request was sent';
};

subtest 'Request to rpc' => sub {
    my $redis = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->(undef, undef, '123') });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });

    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis   => $redis,
        timeout => 0.001,
    );

    # Success request
    my $future = $cg_backend->request([]);

    $redis->mock(subscribe => sub { pop->(); return shift; });
    $redis->mock(on        => sub { pop->($redis, '{"message_id": "1", "response":"any"}') });
    delete $cg_backend->{already_waiting};
    $cg_backend->wait_for_messages();

    my $result = eval { $future->get };

    is_deeply $result,
        {
        message_id => "1",
        response   => "any"
        },
        'Got expected result';

    # Timeout request
    my $err = exception { $cg_backend->request([])->get };
    like $err, qr{^Timeout}, 'Got request time out';
    is_deeply $cg_backend->pending_requests, {}, 'Pending requests should be empty after fail';

    # Redis cmd request
    $redis->mock(_execute => sub { pop->(undef, 'Redis Error', undef) });
    $err = exception { $cg_backend->request([])->get };
    like $err, qr{^Redis Error}, 'Got Redis Error';
    is_deeply $cg_backend->pending_requests, {}, 'Pending requests should be empty after fail';
};

subtest 'Calling callbacks on success requests' => sub {
    my $req_id = '1';
    my $redis  = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->() });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });
    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis   => $redis,
        timeout => 0.001,
    );

    my $c = Test::MockObject->new();
    $c->mock(tx        => sub { 1 });
    $c->mock(wsp_error => sub { {} });
    $c->mock(send      => sub { {} });

    my %was_called;
    my $req_storage = {
        method                  => 'ping',
        stash_params            => [],
        args                    => {},
        before_get_rpc_response => [sub { $was_called{before_get}++ }],
        after_got_rpc_response  => [sub { $was_called{after_get}++ }],
        rpc_failure_cb          => sub { $was_called{failure_cb}++ },
        before_call             => [sub { $was_called{before_call}++ }],
    };

    $cg_backend->call_rpc($c, $req_storage);
    $cg_backend->_on_message(undef, qq[{ "message_id": "$req_id", "response": { "result": {"success": 1}} }]);

    is_deeply \%was_called,
        {
        before_get  => 1,
        after_get   => 1,
        before_call => 1
        },
        'On success request callbacks were called';
};

subtest 'Calling callbacks on failure' => sub {
    my $req_id = 'test_id_123';
    my $redis  = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->(undef, 'Redis Error') });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });
    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis => $redis,
    );

    my %was_called;
    my $req_storage = {
        method                  => 'ping',
        stash_params            => [],
        args                    => {},
        before_get_rpc_response => [sub { $was_called{before_get}++ }],
        after_got_rpc_response  => [sub { $was_called{after_get}++ }],
        rpc_failure_cb          => sub { $was_called{failure_cb}++ },
        before_call             => [sub { $was_called{before_call}++ }],
    };

    #Controller Mock
    my $c = Test::MockObject->new();
    $c->mock(tx        => sub { 1 });
    $c->mock(wsp_error => sub { $was_called{wsp_error}++; return {} });
    $c->mock(send      => sub { $was_called{send}++ });

    $cg_backend->call_rpc($c, $req_storage);
    is_deeply \%was_called,
        {
        failure_cb  => 1,
        before_call => 1,
        wsp_error   => 1,
        send        => 1
        },
        'On failure callbacks were called';
};

subtest 'RPC Category separation enable/disable' => sub {
    my $req_id = '1';
    my $redis  = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->() });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });

    my $cg_mock = Test::MockModule->new('Mojo::WebSocketProxy::Backend::ConsumerGroups');

    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis                    => $redis,
        timeout                  => 0.0001,
        queue_separation_enabled => 1,
        category_timeout_config  => {
            general => 1,
            mt5     => 2
        },
    );

    my $final_category;
    $cg_mock->mock(
        _send_request => sub {
            my ($self, $request_data, $category_name) = @_;
            $final_category = $category_name;
            return $cg_mock->original('_send_request')->($self, $request_data, $category_name);
        });

    #Controller Mock
    my $c = Test::MockObject->new();
    $c->mock(tx        => sub { 1 });
    $c->mock(wsp_error => sub { my %e; @e{qw(type code msg)} = @_[1, 2, 3]; return \%e });

    my $result;
    $c->mock(send => sub { $result = $_[1]->{json} });

    my $req_storage = {
        method       => 'ping',
        category     => 'mt5',
        stash_params => [],
        args         => {},
    };

    $cg_backend->call_rpc($c, $req_storage);
    $cg_backend->_on_message(undef, qq[{"message_id": "$req_id", "response": { "result": {"success": 1}}}]);

    is $final_category, 'mt5', 'Correct category selected';
    is_deeply $result,
        {
        ping     => {success => 1},
        msg_type => 'ping'
        },
        'Got correct rpc response';

    $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis                    => $redis,
        timeout                  => 0.0001,
        queue_separation_enabled => 0,
    );

    $cg_backend->call_rpc($c, $req_storage);
    $cg_backend->_on_message(undef, qq[{"message_id": "$req_id", "response": { "result": {"success": 1}}}]);

    is $final_category, 'general', 'Correct default category';
    $cg_mock->unmock_all();
};

subtest 'RPC Category separtion timeouts' => sub {
    my $req_id = '1';
    my $redis  = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->() });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });

    my $cg_mock = Test::MockModule->new('Mojo::WebSocketProxy::Backend::ConsumerGroups');

    my $timeouts_config = {
        general => 1,
        mt5     => 5,
        payment => 4
    };
    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis                    => $redis,
        timeout                  => 1,
        queue_separation_enabled => 1,
        category_timeout_config  => $timeouts_config,
    );

    my $e = {};
    $cg_mock->mock(
        _send_request => sub {
            my ($self, $request_data, $category_name) = @_;
            my %req_hash = @$request_data;
            $e->{$req_hash{rpc}} = {
                deadline => $req_hash{deadline},
                category => $category_name
            };
            return $cg_mock->original('_send_request')->($self, $request_data, $category_name);
        });

    #Controller Mock
    my $c = Test::MockObject->new();
    $c->mock(tx        => sub { 1 });
    $c->mock(wsp_error => sub { my %e; @e{qw(type code msg)} = @_[1, 2, 3]; return \%e });

    my $result;
    $c->mock(send => sub { $result = $_[1]->{json} });

    # check for valid groups
    foreach my $group (qw(mt5 payment)) {
        my $req_storage = {
            method       => 'ping',
            category     => $group,
            stash_params => [],
            args         => {},
        };

        my $start_time = time();
        $cg_backend->call_rpc($c, $req_storage);
        $cg_backend->_on_message(undef, qq[{"message_id": "$req_id", "response": { "result": {"success": 1}}}]);
        my $current = $e->{$req_storage->{method}};
        is $current->{deadline} - $start_time, $timeouts_config->{$current->{category}}, 'Correct timeout selected';
        is_deeply $result,
            {
            ping     => {success => 1},
            msg_type => 'ping'
            },
            'Got correct rpc response';
    }

    # other methods should use general settings
    my $req_storage = {
        method       => 'ping',
        stash_params => [],
        args         => {},
    };
    my $start_time = time();
    $cg_backend->call_rpc($c, $req_storage);
    $cg_backend->_on_message(undef, qq[{"message_id": "$req_id", "response": { "result": {"success": 1}}}]);
    my $current = $e->{$req_storage->{method}};
    is $current->{deadline} - $start_time, $timeouts_config->{'general'}, 'Correct timeout selected';
    is_deeply $result,
        {
        ping     => {success => 1},
        msg_type => 'ping'
        },
        'Got correct rpc response';

    $cg_mock->unmock_all();
};

subtest 'RPC call: request timeout' => sub {
    my $req_id = 'test_id_123';
    my $redis  = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->(undef, undef, $req_id) });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });
    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis   => $redis,
        timeout => 0.0001,
    );

    #Controller Mock
    my $c = Test::MockObject->new();
    $c->mock(tx        => sub { 1 });
    $c->mock(wsp_error => sub { {msg_type => $_[1], error => {code => $_[2], message => $_[3], $_[4] ? (details => $_[4]) : ()}} });

    my $result;
    $c->mock(send => sub { $result = $_[1]->{json} });

    my $req_storage = {
        method       => 'ping',
        stash_params => [],
        args         => {},
    };

    $cg_backend->call_rpc($c, $req_storage);
    $cg_backend->loop->delay_future(after => 0.001)->get;

    is_deeply $result,
        {
        msg_type => 'ping',
        error    => {
            code    => 'WrongResponse',
            message => 'Sorry, an error occurred while processing your request.'
        }
        },
        'Got expected websocket response';
};

subtest 'RPC call: on redis error' => sub {
    my $req_id = 'test_id_123';
    my $redis  = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->(undef, 'Fail to XADD') });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });
    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis   => $redis,
        timeout => 0.0001,
    );

    #Controller Mock
    my $c = Test::MockObject->new();
    $c->mock(tx        => sub { 1 });
    $c->mock(wsp_error => sub { {msg_type => $_[1], error => {code => $_[2], message => $_[3], $_[4] ? (details => $_[4]) : ()}} });

    my $result;
    $c->mock(send => sub { $result = $_[1]->{json} });

    my $req_storage = {
        method       => 'ping',
        stash_params => [],
        args         => {},
    };

    $cg_backend->call_rpc($c, $req_storage);

    is_deeply $result,
        {
        msg_type => 'ping',
        error    => {
            code    => 'WrongResponse',
            message => 'Sorry, an error occurred while processing your request.'
        }
        },
        'Got expected websocket response';
};

subtest 'RPC call: no error response without active connection' => sub {
    my $req_id = 'test_id_123';
    my $redis  = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->(undef, undef, $req_id) });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });
    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis   => $redis,
        timeout => 0.0001,
    );

    #Controller Mock
    my $c = Test::MockObject->new();
    $c->mock(tx        => sub { undef });
    $c->mock(wsp_error => sub { my %e; @e{qw(type code msg)} = @_[1, 2, 3]; return \%e });

    my $result;
    $c->mock(send => sub { $result = $_[1]->{json} });

    my $req_storage = {
        method       => 'ping',
        stash_params => [],
        args         => {},
    };

    $cg_backend->call_rpc($c, $req_storage);
    $cg_backend->loop->delay_future(after => 0.001)->get;

    is_deeply $result, undef, 'Got no websocket response';
};

subtest 'RPC call: no success response without active connection' => sub {
    my $req_id = 'test_id_123';
    my $redis  = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->(undef, undef, $req_id) });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });
    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis   => $redis,
        timeout => 0.0001,
    );

    #Controller Mock
    my $c = Test::MockObject->new();
    $c->mock(tx        => sub { undef });
    $c->mock(wsp_error => sub { {msg_type => $_[1], error => {code => $_[2], message => $_[3], $_[4] ? (details => $_[4]) : ()}} });

    my $result;
    $c->mock(send => sub { $result = $_[1]->{json} });

    my $req_storage = {
        method       => 'ping',
        stash_params => [],
        args         => {},
    };

    $cg_backend->call_rpc($c, $req_storage);
    $cg_backend->_on_message(undef, qq[{"message_id": "$req_id", "result": {"success": 1}}]);

    is_deeply $result, undef, 'Got no websocket response';
};

subtest 'RPC call: success response' => sub {
    my $req_id = '1';
    my $redis  = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->() });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });
    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis   => $redis,
        timeout => 0.0001,
    );

    #Controller Mock
    my $c = Test::MockObject->new();
    $c->mock(tx        => sub { 1 });
    $c->mock(wsp_error => sub { my %e; @e{qw(type code msg)} = @_[1, 2, 3]; return \%e });

    my $result;
    $c->mock(send => sub { $result = $_[1]->{json} });

    my $req_storage = {
        method       => 'ping',
        stash_params => [],
        args         => {},
    };

    $cg_backend->call_rpc($c, $req_storage);
    $cg_backend->_on_message(undef, qq[{"message_id": "$req_id", "response": { "result": {"success": 1}}}]);

    is_deeply $result,
        {
        ping     => {success => 1},
        msg_type => 'ping'
        },
        'Got no websocket response';
};

subtest 'RPC call: handling error response from rpc server' => sub {
    my $req_id = '1';
    my $redis  = Test::MockObject->new();
    $redis->mock(_execute  => sub { pop->() });
    $redis->mock(subscribe => sub { });
    $redis->mock(on        => sub { });
    my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
        redis   => $redis,
        timeout => 0.0001,
    );

    #Controller Mock
    my $c = Test::MockObject->new();
    $c->mock(tx        => sub { 1 });
    $c->mock(wsp_error => sub { {msg_type => $_[1], error => {code => $_[2], message => $_[3], $_[4] ? (details => $_[4]) : ()}} });

    my $result;
    $c->mock(send => sub { $result = $_[1]->{json} });

    my $req_storage = {
        method       => 'ping',
        stash_params => [],
        args         => {},
    };

    $cg_backend->call_rpc($c, $req_storage);
    $cg_backend->_on_message(undef,
        qq[{"message_id": "$req_id", "response": {"result": { "error": { "code": "TestError", "message_to_client": "Error message", "details":{"field":"test_field"}}}}}]
    );
    is_deeply $result,
        {
        msg_type => 'ping',
        error    => {
            code    => 'TestError',
            message => 'Error message',
            details => {field => 'test_field'}}
        },
        'Got no websocket response';
};

done_testing;
