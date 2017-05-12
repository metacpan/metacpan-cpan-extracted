package Book;

use strict;
use base 'Mojolicious';
use File::Spec::Functions;
use Module::Build;

# This method will run once at server start
sub startup {
    my $self = shift;

    # Routes
    my $r = $self->routes;

    my $build = Module::Build->current;
    my $cache_dir = catdir( $build->base_dir, 't', 'tmp', 'cache' );

    $self->plugin( 'cache-action',
        { options => { driver => 'File', root_dir => $cache_dir } } );

    my $books = $r->route('/books')->to('controller-cache#books');
}

1;
