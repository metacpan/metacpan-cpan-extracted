package Rex::Test::Spec::routes;

use strict;
use warnings;

use Rex -base;

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  my ( $pkg, $file ) = caller(0);
  $self->doit;
  return $self;
}

sub doit {
  my ( $self ) = @_;
  my @ret = route();
  $self->{ret} = \@ret;
}

sub getvalue {
  my ( $self, $key ) = @_;
  return $self->{ret} if !$key;
  return $self->{ret}->[$key];
}

1;
