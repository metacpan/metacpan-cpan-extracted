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
                actions                  => [['success'],],
                before_send_api_response => sub {
                    my ($c, $req_storage, $api_response) = @_;
                    $api_response->{debug_value} = 'dv';
                    $api_response->{success} .= ":modified-for-debug-purposes";
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
    is decode_json($t->message->[1])->{success},     'success-reply:modified-for-debug-purposes';
    is decode_json($t->message->[1])->{debug_value}, 'dv';
}
't::FrontEnd';

done_testing;
