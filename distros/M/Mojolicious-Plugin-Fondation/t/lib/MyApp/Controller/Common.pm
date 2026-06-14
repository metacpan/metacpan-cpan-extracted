package MyApp::Controller::Common;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $c = shift;
    $c->render(text => 'Controller from LOCAL APP (should win)');
}

1;
