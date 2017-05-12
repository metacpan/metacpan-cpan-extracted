package Rex::Endpoint::HTTP::Base;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;

# This action will render a template
sub index {
   my $self = shift;

   $self->render_text("Rex::Endpoint::HTTP");
}

1;
