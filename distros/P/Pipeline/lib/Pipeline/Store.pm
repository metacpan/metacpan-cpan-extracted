package Pipeline::Store;

use strict;
use warnings::register;

use Pipeline::Base;
use base qw( Pipeline::Base );

our $VERSION = "3.12";

sub new {
  my $class = shift;
  if ( $class->in_transaction() ) {
    return $::TRANSACTION_STORE;
  } else {
    my $store = $class->SUPER::new( @_ );
  }
}

sub start_transaction {
  my $self = shift;
  $::TRANSACTION = 1;
  $::TRANSACTION_STORE = $self;
}

sub in_transaction {
  my $self = shift;
  $::TRANSACTION;
}

sub end_transaction {
  my $self = shift;
  if ($self->in_transaction && $self == $::TRANSACTION_STORE) {
    $::TRANSACTION = 0;
  } else {
    $self->emit("cannot clear transaction unless it is called by the same object");
  }
}

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ ) && ref($self) ne 'Pipeline::Store') {
    return 1;
  } else {
    return 0;
  }
}

sub set {
  throw Pipeline::Error::Abstract;
}

sub get {
  throw Pipeline::Error::Abstract;
}

sub DESTROY {
  my $self = shift;
  $self->end_transaction;
}

1;


=head1 NAME

Pipeline::Store - defines the interface for Pipeline store classes

=head1 SYNOPSIS

  use Pipeline::Store; # interface class, does very little

=head1 DESCRIPTION

C<Pipeline::Store> provides a constructor and a generic get/set interface
for any class implementing a store to sit on a Pipeline.  Pipeline stores
are singletons inside the dispatch process.  Ie, if you attempt to construct
a pipeline store in between the dispatch method being called on a pipeline
segment and having the method return a value then you will get the same
store as that segments store() method.

=head1 METHODS

The Pipeline class inherits from the C<Pipeline::Base> class and therefore
also has any additional methods that its superclass may have.

=over 4

=item new()

The C<new> method constructs a new Pipeline::Store object and calls
the C<init> method.  If the transaction flat is set then it returns
the current store singleton.

=item init()

The C<init> method is called by new() to do any construction-time initialization
of an object.

=item start_transaction

Sets the transaction flag, which makes the store object that this is called on a
singleton until end_transaction is called.

=item end_transaction

Clears the transaction flag, which lets you construct new pipeline stores.

=item store( [ store ] )

The C<store> method gets or sets the store in a Pipeline::Store object.  Unless C<init>
is changed the store is set at construction time to a hash reference.

=item get()

Does nothing in Pipeline::Store - exists as a placeholder for subclasses.

=item set()

Does nothing in Pipeline::Store - exists as a placeholder for subclasses.

=back

=head1 SEE ALSO

C<Pipeline>, C<Pipeline::Store::Simple>, C<Pipeline::Store::ISA>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved

This module is released under the same license as Perl itself.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=cut
