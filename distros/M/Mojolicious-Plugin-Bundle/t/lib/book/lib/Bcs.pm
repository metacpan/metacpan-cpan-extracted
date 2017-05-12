package Bcs;

use strict;
use base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Routes
    my $r = $self->routes;
    $self->plugin( 'bcs', { dsn => 'dbi:SQLite:dbname=:memory' } );
    $r->route('/bcs')->to(
        cb => sub {
            my $self = shift;
            $self->render( 'text' => 'bcs text' );
        }
    );
}

1;
