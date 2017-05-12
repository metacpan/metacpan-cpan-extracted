package RWDE::DB::MemcachedAdapter;

use strict;
use warnings;

use Cache::Memcached;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 508 $ =~ /(\d+)/;

sub new {
  my ($class, $params) = @_;

  my $self = {};

  bless $self, $class;

  my $server = $$params{server};

  my $connection = new Cache::Memcached {
    'servers'            => [$server],
    'debug'              => 0,
    'compress_threshold' => 10_000,
  };

  #$memh->enable_compress(0);

  $self->{memh} = $connection;

  return $self;
}

sub add {
  my ($self, $params) = @_;

  my $term = $$params{term};

  $self->{memh}->set($term->get_cache_key(), $term);

  return ();
}

sub get {
  my ($self, $params) = @_;

  return $self->{memh}->get($$params{key});
}

sub delete {
  my ($self, $params) = @_;

  my $term = $$params{term};

  $self->{memh}->delete($term->get_cache_key());

  return;
}

sub disconnect {
  my ($self, $params) = @_;

  return $self->{memh}->disconnect_all();
}

sub flush_all {
  my ($self, $params) = @_;

  return $self->{memh}->flush_all();
}

1;
