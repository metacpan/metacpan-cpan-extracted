package byproduct;

use strict;
use warnings;

use base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Routes
    my $r = $self->routes;

    $self->plugin( 'asset_tag_helpers', { relative_url_root => '/tucker' } );
    my $product = $r->route('/product')->via('get')->to(
        namespace => 'product::Default',
        action    => 'morelist'
    );
}

1;
