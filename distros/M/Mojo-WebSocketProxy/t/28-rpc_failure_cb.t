use strict;
use warnings;
use Test::Warnings;

use t::TestWSP qw/test_wsp/;
use Test::More;
use Test::Mojo;
use JSON::MaybeUTF8 ':v1';
use Mojo::IOLoop;
use Future;
use Test::MockModule;
$ENV{MOJO_INACTIVITY_TIMEOUT} = 1;

my $mocked_response = Test::MockModule->new('Mojo::Message::Response');
my $simulate_error;
#simulate a WrongResponse error
$mocked_response->mock('is_success',      sub { return !$simulate_error });
$mocked_response->mock('is_client_error', sub { return !$simulate_error });

my $mocked_dispatcher = Test::MockModule->new('Mojo::WebSocketProxy::Dispatcher');
my $call_send_count   = 0;
$mocked_dispatcher->mock('send', sub { $call_send_count++; return $mocked_dispatcher->original("send")->(@_) });

package t::FrontEnd {
    use base 'Mojolicious';
    our ($rpc_response_cb_called, $rpc_failure_cb_called, $block_response, $rpc_response_cb_result);

    sub startup {
        my $self = shift;
        $self->plugin(
            'web_socket_proxy' => {
                actions => [[
                        'success',
                        {
                            rpc_response_cb => sub {
                                $rpc_response_cb_called = 1;
                                return $rpc_response_cb_result;
                            },
                            rpc_failure_cb => sub {
                                my ($c, $res, $req_storage) = @_;
                                $c->send({json => {'send_caller' => 'rpc_failure_cb'}}, $req_storage) if $block_response;
                                $rpc_failure_cb_called = 1;
                            },
                            block_response => $block_response,
                        }
                    ],
                ],
                base_path => '/api',
                url       => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
            });
    }
};

use Mojo::IOLoop;

# When rpc has an error ($simulate_error is true), and
# block_response is true, then proxy will not send response to client automatically.
# but rpc_failure_cb still can send back the result itself.
$simulate_error              = 1;
$t::FrontEnd::block_response = 1;
test_wsp {
    my ($t) = @_;
    $call_send_count                     = 0;
    $t::FrontEnd::rpc_failure_cb_called  = 0;
    $t::FrontEnd::rpc_response_cb_called = 0;
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {success => 1}})->message_ok;
    ok(!$t::FrontEnd::rpc_response_cb_called, 'rpc response_cb is not called');
    ok($t::FrontEnd::rpc_failure_cb_called,   'rpc failure cb is called');
    is(decode_json_utf8($t->message->[1])->{send_caller}, 'rpc_failure_cb', 'send is called by rpc failure cb');
    is($call_send_count,                                  1,                'send called only once, in rpc_failure_cb');
}
't::FrontEnd';

# when not blocking response, proxy will send back an error response to client
$t::FrontEnd::block_response = 0;
test_wsp {
    my ($t) = @_;
    $call_send_count                     = 0;
    $t::FrontEnd::rpc_failure_cb_called  = 0;
    $t::FrontEnd::rpc_response_cb_called = 0;
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {success => 1}})->message_ok;
    ok(!$t::FrontEnd::rpc_response_cb_called, 'rpc response_cb is not called');
    ok($t::FrontEnd::rpc_failure_cb_called,   'rpc failure cb is called');
    is(decode_json_utf8($t->message->[1])->{error}{code}, 'WrongResponse', 'send is called after rpc_failure cb');
    is($call_send_count,                                  1,               'send called only once, after called rpc_failure_cb');
}
't::FrontEnd';

# when not blocking response, and no connection error, then rpc_response_cb should return a valid response, and proxy will send back this response
$t::FrontEnd::block_response = 0;
$simulate_error              = 0;
test_wsp {
    my ($t) = @_;
    $call_send_count                     = 0;
    $t::FrontEnd::rpc_failure_cb_called  = 0;
    $t::FrontEnd::rpc_response_cb_called = 0;
    $t::FrontEnd::rpc_response_cb_result = {success => 1};
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {success => 1}})->message_ok;
    ok($t::FrontEnd::rpc_response_cb_called, 'rpc_response_cb is called');
    ok(!$t::FrontEnd::rpc_failure_cb_called, 'rpc_failure_cb is not called');
    diag(explain(decode_json_utf8($t->message->[1])));
    is(decode_json_utf8($t->message->[1])->{success}, 1, 'send is called after rpc_response_cb');
    is($call_send_count,                              1, 'send called only once, after called rpc_failure_cb');
}
't::FrontEnd';

done_testing;
