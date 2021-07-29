package welcome::index;

use Mojo::Base 'Mojolicious::Controller';

sub route() {
	my $c   = shift;
    $c->render(template => 'welcome/index');
}

1;
