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

    our $STASH;
    # does not matter
    sub startup {
        my $self = shift;
        $self->plugin(
            'web_socket_proxy' => {
                actions                  => [['success', {stash_params => [qw/stashed_data/]}],],
                before_send_api_response => sub {
                    my ($c, $req_storage, $api_response) = @_;
                    # no direct way to check that.
                    $STASH = $req_storage->{stash_params};
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
    is decode_json($t->message->[1])->{success}, 'success-reply';
    is_deeply $t::FrontEnd::STASH, [qw/stashed_data/];
}
't::FrontEnd';

done_testing;
