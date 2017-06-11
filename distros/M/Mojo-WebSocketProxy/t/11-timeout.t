use strict;
use warnings;

local $ENV{MOJO_WEBSOCKETPROXY_TIMEOUT} = 1;

use t::TestWSP qw/test_wsp/;
use Test::More;
use Test::Mojo;
use JSON::XS;
use Mojo::IOLoop;
use Future;

subtest "trigger timeout" => sub {

    package t::FrontEnd {
        use base 'Mojolicious';

        sub startup {
            my $self = shift;
            $self->plugin(
                'web_socket_proxy' => {
                    before_forward => [
                        sub {
                            # never ready
                            return Future->new;
                        }
                    ],
                    actions   => [['success'],],
                    base_path => '/api',
                    url       => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
                });
        }
    };

    test_wsp {
        my ($t) = @_;
        $t->websocket_ok('/api' => {});
        $t->send_ok({json => {success => 1}})->message_ok;
        is decode_json($t->message->[1])->{"error"}->{"code"}, 'Timeout';
    }
    't::FrontEnd';
};

done_testing;
