package Sentry::Cache;
use Mojo::Base -base, -signatures;

has _cache => sub { {} };

my $Instance;

sub get_instance ($package) {
  $Instance //= $package->new;
  return $Instance;
}

sub set ($self, $key, $value) {
  $self->_cache->{$key} = $value;
}

sub get ($self, $key) {
  return $self->_cache->{$key};
}

1;
