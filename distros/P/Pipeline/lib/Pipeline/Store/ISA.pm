package Pipeline::Store::ISA;

use strict;
use warnings::register;

use Pipeline::Store;
use base qw ( Pipeline::Store );

use Class::ISA;

our $VERSION = "3.12";

sub init {
  my $self = shift;
  if ( $self->SUPER::init( @_ )) {
    $self->obj_store( {} );
    $self->isa_store( {} );
  }
}

sub obj_store {
  my $self = shift;
  if (@_) {
    $self->{ store } = shift;
    return $self;
  }
  return $self->{ store };
}

sub isa_store {
  my $self = shift;
  if (@_) {
    $self->{ isa_store } = shift;
    return $self;
  }
  return $self->{ isa_store };
}

sub set {
  my $self = shift;
  my $obj  = shift;
  my @isa  = Class::ISA::super_path( ref($obj) );
  my $store = $self->isa_store;
  foreach my $isa (@isa) {
    if (!exists $self->isa_store->{ $isa }) {
      $store->{ $isa } = {};
    }
    $store->{ $isa }->{ ref($obj) } = 1;
    #push @{$store->{ $isa }}, ref($obj);
  }
  $self->obj_store->{ref($obj)} = $obj;
  $self->emit("setting object " . ref($obj));
  return $self;
}

sub get {
  my $self = shift;
  my $key  = shift;

  $self->emit("$key requested");

  if (exists( $self->obj_store->{ $key })) {
    $self->emit("returning object $key");
    return $self->obj_store->{ $key };
  } elsif (exists( $self->isa_store->{$key})) {
    my @objs;
    foreach my $thing ( keys %{$self->isa_store->{ $key }} ) {
      push @objs, $self->get( $thing );
    }
    return [ @objs ] if (@objs > 1);
    return $objs[0];
  } else {
    $self->emit("no object $key");
    return undef;
  }
}

1;


=head1 NAME

Pipeline::Store::ISA - inheritance-based store for pipelines

=head1 SYNOPSIS

  use Pipeline::Store::ISA;

  my $store = Pipeline::Store::ISA->new();
  $store->set( $object );
  my $object = $store->get( $class );

=head1 DESCRIPTION

C<Pipeline::Store::ISA> is a slightly more complex implementation of a
Pipeline store than C<Pipeline::Store::Simple>. It stores things as in a
hashref indexed by classname, and also their inheritance tree. You can add
an object to a store by calling the set method with an object, and you can
get an object by calling the get method with the classname or parent classname
of the object you wish to retrieve.

C<Pipeline::Store::ISA> inherits from the C<Pipeline::Store> class and
includes its methods also.

=head1 METHODS

=over 4

=item set( OBJECT )

The C<set> method stores an object specified by OBJECT in itself.  Replaces
existing objects of the same type.

=item get( SCALAR )

The C<get> method attempts to return an object of the class specified
by SCALAR.  If an object of that class does not exist in the store it
returns undef instead.  In the case that you request a super class of
multiple objects an array reference will be returned containing all
the objects that are blessed into child classes of SCALAR.

=back

=head1 SEE ALSO

C<Pipeline>, C<Pipeline::Store>, C<Pipeline::Store::Simple>

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd. All Rights Reserved.

This software is distributed under the same terms as Perl itself.

=cut


