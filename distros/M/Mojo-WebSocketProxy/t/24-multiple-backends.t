use strict;
use warnings;

use t::TestWSP qw/test_wsp/;
use Test::More;
use Test::Mojo;
use JSON::MaybeUTF8 ':v1';
use Mojo::IOLoop;

package t::FrontEnd {
    use base 'Mojolicious';

    sub startup {
        my $self = shift;

        my $url = $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined");
        (my $url2 = $url) =~ s{/rpc/}{/rpc2/};

        $self->plugin(
            'web_socket_proxy' => {
                actions => [['success'], ['faraway', {backend => "rpc2"}],],
                backends => {
                    rpc2 => {url => $url2},
                },
                base_path => '/api',
                url       => $url,
            });
    }
};

test_wsp {
    my ($t) = @_;
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {success => 1}})->message_ok;
    is(decode_json_utf8($t->message->[1])->{success}, 'success-reply');

    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {faraway => 1}})->message_ok;
    is(decode_json_utf8($t->message->[1])->{faraway}, 'faraway-reply');
}
't::FrontEnd', 't::SampleRPC2';

done_testing;

package t::SampleRPC2;

use MojoX::JSON::RPC::Service;
use Mojo::Base 'Mojolicious';
use JSON::MaybeUTF8 ':v1';

sub startup {
    my $self = shift;
    $self->plugin(
        'json_rpc_dispatcher',
        services => {
            '/rpc/success' => MojoX::JSON::RPC::Service->new->register(
                'success',
                sub {
                    return 'success-reply';
                }
            ),
            '/rpc/echo' => MojoX::JSON::RPC::Service->new->register(
                'echo',
                sub {
                    $self->log->debug('$_[0]->{args} = ' . encode_json_utf8($_[0]->{args}));
                    return $_[0]->{args};
                }
            ),
            '/rpc2/faraway' => MojoX::JSON::RPC::Service->new->register(
                'faraway',
                sub {
                    return 'faraway-reply';
                }
            ),
        });
}

1;
