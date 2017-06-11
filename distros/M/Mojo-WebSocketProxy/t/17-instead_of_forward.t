use strict;
use warnings;

use t::TestWSP qw/test_wsp/;
use Test::More;
use Test::Mojo;
use JSON::XS;
use Mojo::IOLoop;
use Future;

package t::FrontEnd {
    use base 'Mojolicious';
    # does not matter
    sub startup {
        my $self = shift;
        $self->plugin(
            'web_socket_proxy' => {
                actions => [[
                        'success',
                        {
                            instead_of_forward => sub {
                                shift->call_rpc({
                                    args     => {param => 1},
                                    method   => 'echo',
                                    msg_type => 'success',
                                });

                            }
                        }
                    ],
                ],
                base_path => '/api',
                url       => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
            });
    }
};

test_wsp {
    my ($t) = @_;
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {success => 1}})->message_ok;
    is decode_json($t->message->[1])->{msg_type}, 'success';
    is_deeply decode_json($t->message->[1])->{success}, {param => 1};
}
't::FrontEnd';

done_testing;
