package welcome::subfolder::index;

use Mojo::Base 'Mojolicious::Controller';

sub route() {
    my $c = shift;
    $c->render( template => 'welcome/subfolder/index' );
}

1;
