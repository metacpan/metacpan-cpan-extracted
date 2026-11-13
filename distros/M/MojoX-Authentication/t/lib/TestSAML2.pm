package TestSAML2;

# A real MojoX::Authentication::Model::SAML2 (default remaps, real cache),
# except that parse_assertion skips the IdP: it returns whatever was set
# with next_user, as if it came in a valid assertion.

use v5.24;
use Moo;
use experimental qw< signatures >;
use FindBin qw< $Bin >;

extends 'MojoX::Authentication::Model::SAML2';

has next_user => (is => 'rw');

around BUILDARGS => sub ($orig, $class, @args) {
   return $class->$orig(
      idp => "$Bin/data/test-idp-metadata.xml",
      sp_configuration => {
         identifier => 'https://srv.example.com/sp',
         key        => "$Bin/../eg/server.key",
      },
      @args,
   );
};

sub parse_assertion ($self, $id, $response) {
   my $user = $self->_normalize_user({ $self->next_user->%* });
   $self->_cache_user($user);
   return $user;
}

1;
