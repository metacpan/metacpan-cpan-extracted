package MojoX::Authentication::Model::SAML2::Hash;
{ our $VERSION = '0.003' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use Storable qw< dclone >;
use namespace::clean;

has _store => (is => 'ro', default => sub { return {} });

sub get ($self, $key) {
   defined(my $rec = $self->_store->{$key}) or return;
   return dclone($rec->{data}) if $rec->{expire} > time();
   $self->wipe($key);
   return;
}

sub set ($self, $data, $key, $expire) {
   $self->_store->{$key} = {
      expire => $expire,
      data   => $data,
   };
   return $self;
}

sub wipe ($self, $key) {
   delete($self->_store->{$key});
   return $self;
}

1;
