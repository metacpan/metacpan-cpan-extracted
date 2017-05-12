package RWDE::DB::MemcachedRegistry;

use strict;
use warnings;

use Error qw(:try);

use RWDE::Configuration;
use RWDE::Exceptions;
use RWDE::DB::MemcachedAdapter;

use base qw( RWDE::Singleton);

my $unique_instance;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 508 $ =~ /(\d+)/;

sub get_instance {
  my ($self, $params) = @_;

  if (ref $unique_instance ne $self) {
    $unique_instance = $self->new;
  }

  return $unique_instance;
}

sub initialize {
  my ($self, $params) = @_;

  return ();
}

sub _connect {
  my ($self, $params) = @_;

  $self->{memh} = new RWDE::DB::MemcachedAdapter { server => RWDE::Configuration->CACHE . ":11211" };

  return ();
}

sub get_memh {
  my ($self, $params) = @_;

  my $memcached_registry = $self->get_instance();

  unless (defined $memcached_registry->{memh}) {
    $memcached_registry->_connect();
  }

  return $memcached_registry->{memh};
}

sub disconnect_all {
  my ($self, $params) = @_;

  my $memcached_registry = $self->get_instance();

  $memcached_registry->{memh}->disconnect_all();

  return ();
}

sub flush_all {
  my ($self, $params) = @_;

  my $memcached_registry = $self->get_instance();

  my $memh = RWDE::DB::MemcachedRegistry->get_memh();

  if ($memh) {
    print "Flushing";
    if ($memh->flush_all()) {
      print ": success! \n";
    }

    else {
      print ": failed! \n";
    }

  }
  return ();
}

1;
