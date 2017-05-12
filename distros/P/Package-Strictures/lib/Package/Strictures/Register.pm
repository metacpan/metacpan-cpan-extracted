use 5.006;    # 6 = pragmas, our, 4 = __PACAKGE__
use strict;
use warnings;

package Package::Strictures::Register;

our $VERSION = '1.000001';

# ABSTRACT: Create compile-time constants that can be tweaked by users with Package::Strictures.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Package::Strictures::Registry ();
use Carp                          ();

sub import {
  my ( $self, %params ) = @_;

  if ( not %params ) {
    Carp::carp( __PACKAGE__ . ' called with no parameters, skipping magic' );
    return;
  }

  my (@caller) = caller;
  my $package = $caller[0];
  $package = $params{-for} if exists $params{-for};

  if ( not exists $params{-setup} ) {
    Carp::croak("Can't setup strictures for package '$package', need -setup ");
  }

  $self->_setup( $params{-setup}, $package );

  return;
}

sub _setup {
  my ( $self, $params, $package ) = @_;

  my $reftype = ref $params;

  if ( not 'HASH' eq $reftype ) {
    Carp::croak(qq/ -setup => can presently only support a HASH. Got '$reftype'/);
  }

  if ( ( not exists $params->{-strictures} ) && ( not exists $params->{-groups} ) ) {
    Carp::croak('Neither -setup => { -strictures }  or -setup => { -groups } provided.');
  }

  if ( exists $params->{-groups} ) {
    Carp::carp('-groups support is not yet implemented');
  }

  $params->{-strictures} = {} unless exists $params->{-strictures};
  $params->{-groups}     = {} unless exists $params->{-groups};

  $self->_setup_strictures( $params->{-strictures}, $package );

  return;
}

sub _setup_strictures {
  my ( $self, $strictures, $package ) = @_;
  my $reftype = ref $strictures;

  if ( not 'HASH' eq $reftype ) {
    Carp::croak( qq/Can't handle anything except a HASH ( Got $reftype )/
        . qq/ for param -setup => { -strictures =>  } in -setup for $package/ );
  }

  for my $subname ( keys %{$strictures} ) {

    $self->_setup_stricture( $strictures->{$subname}, $package, $subname );
  }

  return;
}

sub _setup_stricture {
  ## no critic 'ProhibitNoStrict'
  my ( $self, $prototype, $package, $name ) = @_;
  if ( not exists $prototype->{default} ) {
    Carp::croak("Prototype for `$package`::`$name` lacks a [required] ->{'default'} ");
  }

  $self->_advertise_stricture( $package, $name );

  require Import::Into;
  require constant;

  constant->import::into( $package, $name, $self->_fetch_stricture_value( $package, $name, $prototype->{default} ) );

  return;
}

sub _advertise_stricture {
  my ( undef, $package, $name ) = @_;
  Package::Strictures::Registry->advertise_value( $package, $name );
  return;
}

sub _fetch_stricture_value {
  my ( undef, $package, $name, $default ) = @_;
  if ( Package::Strictures::Registry->has_value( $package, $name ) ) {
    return Package::Strictures::Registry->get_value( $package, $name );
  }
  return $default;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Package::Strictures::Register - Create compile-time constants that can be tweaked by users with Package::Strictures.

=head1 VERSION

version 1.000001

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
