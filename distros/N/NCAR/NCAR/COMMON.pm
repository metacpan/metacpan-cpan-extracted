package NCAR::COMMON;

our $VERSION = '0.01';

use strict;
use Carp qw( croak );

sub import {
  my $package = shift;
  my @C = @_;
  my $caller = caller;
  for( @C ) {
    s/^%//o;
    eval {
      require "NCAR/COMMON/$_.pl";
    };
    $@ && croak( "Undefined NCAR::COMMON $_" );
    no strict 'refs';
    *{"$caller\::$_"} = \%{"NCAR::COMMON::$_"};
  }
}



sub TIEHASH {
  my $class = shift;
  my %args = @_;
  return bless { 
           name    => $args{-name}, 
           id      => $args{-id}, 
           vars    => $args{-vars},
         }, $class;
}

sub FETCH {
  my ( $self, $key, $value ) = @_;
  croak( "$key not defined in NCAR::COMMON::$self->{name}" )
  unless( exists $self->{vars}{$key} );
  &NCAR::ncar_common_variable_get( 
        $self->{id}, 
        $value, 
        $self->{vars}{$key}[0], 
        $self->{vars}{$key}[1],
        $self->{vars}{$key}[2],
        $self->{vars}{$key}[3],
  );
  return $value;
}

sub STORE {
  my ( $self, $key, $value ) = @_;
  croak( "$key not defined in NCAR::COMMON::$self->{name}" )
  unless( exists $self->{vars}{$key} );
  croak( "Cannot set a non-scalar value in NCAR::COMMON::$self->{name}" )
  if( @{ $self->{vars}{$key}[3] } );
  &NCAR::ncar_common_variable_set( 
        $self->{id}, 
        $value, 
        $self->{vars}{$key}[0], 
        $self->{vars}{$key}[1],
        $self->{vars}{$key}[2],
  );
  return $value;
}

sub CLEAR {

}

sub DELETE {

}

sub EXISTS {
  my ( $self, $key, $value ) = @_;
  exists $self->{vars}{$key};
}

sub FIRSTKEY {
  my ( $self, $key, $value ) = @_;
  each %{ $self->{vars} };
}

sub NEXTKEY {
  my ( $self, $key, $value ) = @_;
  each %{ $self->{vars} };
}

1;

