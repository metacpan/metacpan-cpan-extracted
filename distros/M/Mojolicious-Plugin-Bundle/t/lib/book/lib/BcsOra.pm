package BcsOra;

use strict;
use base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Routes
    my $r = $self->routes;
    $self->plugin(
        'bcs-oracle',
        {   dsn      => 'dbi:Oracle:',
            user     => 'scott',
            password => 'tiger'
        }
    );
    $r->route('/bcsora')->to(
        sub {
            my $self = shift;
            $self->render( 'text' => 'bcs ora text' );
        }
    );
}

1;
