package Pipeline::Store::Simple;

use strict;
use warnings::register;

use Pipeline::Store;
use base qw( Pipeline::Store );

our $VERSION = "3.12";

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->storehash( {} );
    return 1;
  } else {
    return 0;
  }
}

sub storehash {
  my $self = shift;
  my $hash = shift;
  if (defined( $hash )) {
    $self->{ storehash } = $hash;
    return $self;
  } else {
    return $self->{ storehash };
  }
}

sub set {
  my $self = shift;
  my $obj  = shift;
  if (defined( $obj )) {
    $self->storehash->{ ref($obj) } = $obj;
  }
  return $self;
}

sub get {
  my $self = shift;
  my $key  = shift;
  return $self->storehash->{ $key };
}

1;


=head1 NAME

Pipeline::Store::Simple - simple store for pipelines

=head1 SYNOPSIS

  use Pipeline::Store::Simple;

  my $store = Pipeline::Store::Simple->new();
  $store->set( $object );
  my $object = $store->get( $class );

=head1 DESCRIPTION

C<Pipeline::Store::Simple> is a simple implementation of a Pipeline store.
It stores things as in a hashref indexed by classname.  You can add an object
to a store by calling the set method with an object, and you can get an object
by calling the get method with the classname of the object you wish to retrieve.

C<Pipeline::Store::Simple> inherits from the C<Pipeline::Store> class and
includes its methods also.

=head1 METHODS

=over 4

=item set( OBJECT )

The C<set> method puts OBJECT in the store.

=item get( SCALAR )

The C<get> method attempts to return an object of the class specified
by SCALAR.  If an object of that class does not exist in the store it
returns undef instead.

=back

=head1 SEE ALSO

C<Pipeline>, C<Pipeline::Store>, C<Pipeline::Store::ISA>

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This software is released under the same terms as Perl itself.
=cut



