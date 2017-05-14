use 5.012;
use warnings;

package MyApp::Foo;
use Mojo::Base 'Mojolicious::Controller';

use Plack::Session;

use Mojo::Template;
my $mt = Mojo::Template->new;

sub hello {
    my $self    = shift;
    my $session = Plack::Session->new( $self->req->env );

    my $email = $session->get('email');
    if ($email) {
        $self->cookie( email => $email, { path => '/' } );
    }

    $self->render( template => 'hello', email => $email );
}

1;
