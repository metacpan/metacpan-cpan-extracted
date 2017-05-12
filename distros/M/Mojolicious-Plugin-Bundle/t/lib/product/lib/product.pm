package product;

use strict;
use warnings;

use base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Routes
    my $r = $self->routes;

    $self->plugin('asset_tag_helpers');

    my $product = $r->waypoint('/product')->via('get')->to('default#list');
    my $type = $product->waypoint('/:type')->via('get')->to('default#type');
    $type->route('/:id')->via('get')->to('default#show');

}

1;
