package t::SampleRPC;

use strict;
use warnings;

use MojoX::JSON::RPC::Service;
use Mojo::Base 'Mojolicious';
use JSON::XS;

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
                    $self->log->debug('$_[0]->{args} = ' . encode_json($_[0]->{args}));
                    return $_[0]->{args};
                }
            ),
        });
}

1;
