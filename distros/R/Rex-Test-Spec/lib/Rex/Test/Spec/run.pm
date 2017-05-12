package Rex::Test::Spec::run;

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
  run($self->{name}, sub{
    ($self->{stdout}, $self->{stderr}) = @_;
  });
}

sub getvalue {
  my ( $self, $key ) = @_;
  return $self->{$key};
}

1;
