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
                            response => sub {
                                my ($rpc_response, $api_response, $req_storage) = @_;
                                return {
                                    my_response => $rpc_response,
                                    additional  => 'details',
                                };
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
    is decode_json($t->message->[1])->{my_response}, 'success-reply';
    is decode_json($t->message->[1])->{additional},  'details';
}
't::FrontEnd';

done_testing;
