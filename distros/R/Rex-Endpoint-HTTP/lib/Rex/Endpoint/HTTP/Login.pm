package Rex::Endpoint::HTTP::Login;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;

# This action will render a template
sub index {
   my $self = shift;
   $self->render_json({ok => Mojo::JSON->true});
}

1;
