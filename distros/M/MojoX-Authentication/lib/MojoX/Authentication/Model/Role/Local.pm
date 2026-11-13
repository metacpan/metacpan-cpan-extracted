package MojoX::Authentication::Model::Role::Local;
{ our $VERSION = '0.100' }

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

requires 'load_user_by_username';

has crypt_passphrase => (
   is => 'ro',
   default => undef,
   coerce => \&coerce_crypt_passphrase,
);

has key_for_secret => (
   is => 'ro',
   default => 'secret',
   isa => sub ($x) {
      ouch 400, 'key_for_secret must be defined' unless defined($x);
   },
);

has protected_keys => (
   is => 'ro',
   default => sub { return [] },
   isa => sub ($x) {
      ouch 400, 'protected_keys must be an array reference'
         if ref($x) ne 'ARRAY';
   },
   init_arg => 'protected_keys',
);

has _hashed_fake => (is => 'lazy');

sub _build__hashed_fake ($self) { $self->hash_secret('foo') }

sub protected_keys_list ($self) {
   return ($self->key_for_secret, $self->protected_keys->@*);
}

sub handles_username ($self, $controller, $name) {
   return undef unless defined($name);
   return 0xdef if $self->load_user_by_username($controller, $name);
   return undef;
}

sub hash_secret ($self, $secret) {
   $self->crypt_passphrase->hash_password($secret);
}

sub run_fake_validation ($self) {
   $self->crypt_passphrase->verify_password(bar => $self->_hashed_fake);
   ouch 401, 'Unauthorized';
}

sub tamed_user_record ($self, $user) {
   my %u = $user->%*;
   delete($u{$_}) for $self->protected_keys_list;
   return \%u;
}

sub user_for_save ($self, $user, $is_secret_cleartext) {
   my %u = $user->%*;
   my $key = $self->key_for_secret;
   $u{$key} = $self->hash_secret($u{$key})
      if length($u{$key} // '') && $is_secret_cleartext;
   return \%u;
}

sub validate_user ($self, $controller, $name, $secret, $extra) {
   return unless defined($name);
   my $user = $self->load_user_by_username($controller, $name) or return;
   my $hash = $user->{$self->key_for_secret};
   return $self->run_fake_validation unless length($hash // '');
   $self->crypt_passphrase->verify_password($secret, $hash)
      or ouch 401, 'Unauthorized';
   return $name;
}

1;
