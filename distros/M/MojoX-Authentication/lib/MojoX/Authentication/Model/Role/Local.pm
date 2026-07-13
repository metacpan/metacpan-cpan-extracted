package MojoX::Authentication::Model::Role::Local;
{ our $VERSION = '0.001' }

use v5.24;
use Moo::Role;
use experimental qw< signatures >;
use Ouch qw< :trytiny_var >;
use Scalar::Util qw< blessed >;

sub coerce_crypt_passphrase ($x) {
   return $x if blessed($x);
   require Crypt::Passphrase;
   return Crypt::Passphrase->new(encoder => 'Argon2', ($x // {})->%*);
}

use namespace::clean;

requires 'load_user_by_name';

has crypt_passphrase => (
   is => 'ro',
   default => undef,
   coerce => \&coerce_crypt_passphrase,
);

sub handles_username ($self, $controller, $name) {
   return unless defined($name);
   return 'yep' if $self->load_user_by_name($controller, $name);
   return undef;
}

sub hash_secret ($self, $secret) {
   $self->crypt_passphrase->hash_password($secret);
}

sub validate_user ($self, $controller, $name, $secret, $extra) {
   return unless defined($name);
   my $user = $self->load_user_by_name($controller, $name) or return;

#   use Data::Dumper;
#   $controller->log->trace("local validate user <$name>, loaded: "
#      . Dumper($user));

   my $cp = $self->crypt_passphrase;
   my $check = $cp->verify_password($secret, $user->{secret});
   return $check ? $name : undef;  # externally visible id is $name
}

1;
