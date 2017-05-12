package Rex::Endpoint::HTTP::Execute;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;

use Rex::Endpoint::HTTP::Interface::Exec;

# This action will render a template
sub index {
   my $self = shift;

   my $ref = $self->req->json;
   my $cmd = $ref->{exec};

   my ($out);
   eval {
      my $iface = Rex::Endpoint::HTTP::Interface::Exec->create;
      $out = $iface->exec($cmd);
   };

   if($@) {
      return $self->render_json({ok => Mojo::JSON->false, output => "$@", retval => 1});
   }

   $self->render_json({ok => Mojo::JSON->true, output => $out, retval => $?});
}

1;
