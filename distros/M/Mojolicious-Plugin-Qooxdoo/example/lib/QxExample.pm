package QxExample;
use strict;
use warnings;

use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;
    $self->plugin('qooxdoo',{
        prefix => '/root',
        path => 'jsonrpc',
        controller => 'JsonRpcService'
    });
}

1;
