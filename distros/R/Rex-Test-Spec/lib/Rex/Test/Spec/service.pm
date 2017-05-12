package Rex::Test::Spec::service;

use strict;
use warnings;

use Rex -base;

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  my ( $pkg, $file ) = caller(0);

  return $self;
}

sub ensure {
  my ( $self ) = @_;
  my $status = service($self->{name}, "status");
  return $status ? 'running' : 'stopped';
}

sub getvalue {
  my ( $self, $key ) = @_;
  return $self->$key;
}

1;
