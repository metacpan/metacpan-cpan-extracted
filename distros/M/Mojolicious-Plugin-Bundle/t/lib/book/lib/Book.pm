package Book;

use strict;
use base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Routes
    my $r = $self->routes;
    $self->plugin(
        'yml_config',
        {   stash_key => 'myconfig',
            file      => $self->home->rel_file('conf/book.yaml')
        }
    );
    $r->route('/books')->to(
        cb => sub {
            my $self = shift;
            $self->render( 'text' => 'my yaml plugin' );
        }
    );
}

1;
