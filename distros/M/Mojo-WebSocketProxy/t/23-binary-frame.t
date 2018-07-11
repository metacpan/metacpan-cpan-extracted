use strict;
use warnings;

use t::TestWSP qw/test_wsp/;
use Test::More;
use Test::Mojo;
use JSON::MaybeUTF8 ':v1';
use Mojo::IOLoop;
use Future;
use Path::Tiny;

package t::FrontEnd {
    use base 'Mojolicious';

    sub startup {
        my $self = shift;
        $self->plugin(
            'web_socket_proxy' => {
                actions      => [],
                binary_frame => sub {
                    my ($c, $bytes) = @_;
                    my ($len, $payload) = unpack 'Na*', $bytes;
                    die 'Invalid data' if $len != length $payload;
                    $c->send({json => {payload => $payload}});
                },
                base_path => '/api',
                url       => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
            });
    }
};

test_wsp {
    my ($t) = @_;
    my $expected = path('t/data/tux.png')->slurp;
    $t->websocket_ok('/api' => {});
    $t->send_ok({
            binary => pack 'Na*',
            length $expected, $expected
        })->message_ok;
    is(decode_json_utf8($t->message->[1])->{payload}, $expected);
}
't::FrontEnd';

done_testing;
