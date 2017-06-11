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
                actions   => [['success'],],
                base_path => '/api',
                url       => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
            });
    }
};

test_wsp {
    my ($t) = @_;
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {non_existing_action => 1}})->message_ok;
    is decode_json($t->message->[1])->{"error"}->{"code"}, 'UnrecognisedRequest';
}
't::FrontEnd';

done_testing;
