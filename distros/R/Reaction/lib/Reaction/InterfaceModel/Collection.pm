package Reaction::InterfaceModel::Collection;

use Reaction::Class;
use Scalar::Util qw/refaddr blessed/;
use aliased 'Reaction::Meta::InterfaceModel::Object::DomainModelAttribute';

# WARNING - DANGER: this is just an RFC, please DO NOT USE YET

use namespace::clean -except => [ qw(meta) ];
extends "Reaction::InterfaceModel::Object";



# consider supporting slice, first, iterator, last etc.
# pager functionality should probably be a role

# IM objects don't have write methods because those are handled through actions,
# no support for write actions either unless someone makes a good case for it
# many models may not even be writable, so we cant make that assumption...

# I feel like we should hasa result_class or object_class ?
# having this here would remove a lot of PITA complexity from
# ObjectClass and SchemaClass when it comes to munging with internals

#Answer: No, because collections should be able to hold more than one type of object

# ALL IMPLEMENTATIONS ARE TO ILLUSTRATE POSSIBLE BEHAVIOR ONLY. DON'T CONSIDER
# THEM CORRECT, OR FINAL. JUST A ROUGH DRAFT.

#domain_models are 'ro' unless otherwise specified
has _collection_store => (
                          is  => 'rw',
                          isa => 'ArrayRef',
                          lazy_build => 1,
                          clearer    => "_clear_collection_store",
                          metaclass  => DomainModelAttribute,
                         );

has 'member_type' => (is => 'ro', isa => 'ClassName');
sub _build__collection_store { [] };
sub members {
  my $self = shift;
  return @{ $self->_collection_store };
};

#return new member or it's index # ?
sub add_member {
  my $self = shift;
  my $new  = shift;
  confess "Argument passed is not an object" unless blessed $new;
  confess "Object Passed does not meet constraint isa Reaction::InterfaceModel::Object"
    unless $new->isa('Reaction::InterfaceModel::Object');
  my $store = $self->_collection_store;
  push @$store, $new;
  return $#$store; #return index # of inserted item
};
sub remove_member {
  my $self = shift;
  my $rem = shift;
  confess "Argument passed is not an object" unless blessed $rem;
  confess "Object Passed does not meet constraint isa Reaction::InterfaceModel::Object"
    unless $rem->isa('Reaction::InterfaceModel::Object');

  my $addr = refaddr $rem;
  @{ $self->_collection_store } = grep {$addr ne refaddr $_ } @{ $self->_store };
};

#that was easy..
sub count_members {
  my $self = shift;
  return scalar @{ $self->_collection_store };
};

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::InterfaceModel::Collection - Generic collections of
L<Reaction::InterfaceModel::Object>s

=head1 DESCRIPTION

The base class for C<InterfaceModel::Collection>s. The functionality implemented here
is minimal and it is expected that specialized collections be built by sublclassing
this and exploiting the roles system.

=head1 METHODS

=head2 members

Returns a list containing all known members of the collection

=head2 add_member $object

Will add the object passed to the collection

=head2 remove_member $object

Removed the object passed from the collection, if present

=head2 count_members

Returns the number of objects in the collection.

=head1 ATTRIBUTES

=head2 _collection_store

Read-write & lazy_build. Holds the arrayref where the collection of objects is
presently stored. Has a clearer of C<_clear_collection_store> and a predicate of
 C<_has_collection_store>.

=head1 PRIVATE METHODS

_build__collection_store

Builder method for attribute_collection_store, returns an empty arrayref

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
