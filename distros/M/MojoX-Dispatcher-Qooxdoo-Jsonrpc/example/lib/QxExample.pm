package QxExample;
use strict;
use warnings;

use QxExample::JsonRpcService;

use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;
    $self->plugin('qooxdoo_jsonrpc',{
        services => {
            rpc => QxExample::JsonRpcService->new()
        }
    });
}

1;
