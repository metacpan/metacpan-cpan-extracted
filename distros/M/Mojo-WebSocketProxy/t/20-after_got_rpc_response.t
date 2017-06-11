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

    sub startup {
        my $self = shift;
        $self->plugin(
            'web_socket_proxy' => {
                actions => [[
                        'success',
                        {
                            after_got_rpc_response => sub {
                                my ($c, $req_storage, $rps_response) = @_;
                                # modifications of $req_storage will not affect API response.
                                $req_storage->{after_got_rpc_response} = 'ok';
                            }
                        }
                    ],
                ],
                before_send_api_response => sub {
                    my ($c, $req_storage, $api_response) = @_;
                    $api_response->{after_got_rpc_response} = $req_storage->{after_got_rpc_response};
                },
                base_path => '/api',
                url       => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
            });
    }
};

test_wsp {
    my ($t) = @_;
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {success => 1}})->message_ok;
    is decode_json($t->message->[1])->{success},                'success-reply';
    is decode_json($t->message->[1])->{after_got_rpc_response}, 'ok';
}
't::FrontEnd';

done_testing;
