package Reaction::UI::ViewPort::Collection;

use Reaction::Class;
use Scalar::Util qw/blessed/;
use aliased 'Reaction::InterfaceModel::Collection' => 'IM_Collection';
use aliased 'Reaction::UI::ViewPort::Object';

use MooseX::Types::Moose qw/Str HashRef/;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort';

with 'Reaction::UI::ViewPort::Collection::Role::Pager';
with 'Reaction::UI::ViewPort::Role::Actions';

has members => (is => 'rw', isa => 'ArrayRef', lazy_build => 1);

has collection         => (is => 'ro', isa => IM_Collection, required   => 1);
has current_collection => (is => 'rw', isa => IM_Collection, lazy_build => 1);

has member_args => ( is => 'rw', isa => HashRef, lazy_build => 1);
has member_class => ( is => 'ro', isa => Str, lazy_build => 1);

sub BUILD {
  my ($self, $args) = @_;
  if( my $member_args = delete $args->{Member} ){
    $self->member_args( $member_args );
  }
}

sub _build_member_args { {} }

sub _build_member_class { Object };

after clear_current_collection => sub{
  shift->clear_members; #clear the members the current collection changes, duh
};

sub _build_current_collection {
  return $_[0]->collection;
}

#I'm not really sure why this is here all of a sudden.
sub model { shift->current_collection }

sub _build_members {
  my ($self) = @_;
  my (@members, $i);
  my $args = $self->member_args;
  my $builders = {};
  my $field_orders = {};
  my $ctx = $self->ctx;
  my $loc = join('-', $self->location, 'member');
  my $class = $self->member_class;

  #replace $i with a real unique identifier so that we don't run a risk of
  # events being passed down to the wrong viewport. for now i disabled event
  # passing until i fix this (groditi)
  for my $obj ( $self->current_collection->members ) {
    my $type = blessed $obj;
    my $builder_cache = $builders->{$type} ||= {};
    my @order;
    if( exists $args->{computed_field_order} ){
      @order = (computed_field_order => $args->{computed_field_order});
    } elsif( exists $field_orders->{$type} ) {
      @order = (computed_field_order => $field_orders->{$type});
    }

    my $member = $class->new(
      ctx => $ctx,
      model => $obj,
      location => join('-', $loc, $i++),
      builder_cache => $builder_cache,
      @order, %$args,
    );

    #cache to prevent the sort function from having to be run potentially
    #hundreds of times
    $field_orders->{$type} ||= $member->computed_field_order unless @order;
    push(@members, $member);
  }
  return \@members;
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::ViewPort::Collection

=head1 DESCRIPTION

Creates, from an InterfaceModel::Collection, a list of viewports representing
each member of the collection.

=head1 ATTRIBUTES

=head2 collection

Required read-only L<InterfaceModel::Collection|Reaction::InterfaceModel::Collection>
This is the original collection.

=head2 current_collection

Read-only, lazy-building
L<InterfaceModel::Collection|Reaction::InterfaceModel::Collection>
This is the collection that will be used to create C<members> and should be
altered to reflect any ordering, paging, etc. By default this is the
same thing as C<collection>.

=head2 member_args

A read-write HASH ref of additional parameters to pass to the C<member_class>
constructor as items are instantiated.

=head2 member_class

The class to use when instantiating items to represent the member items.

See: L<Object|Reaction::UI::ViewPort::Object>,
L<Member|Reaction::UI::ViewPort::Collection::Grid::Member>.

=head1 INTERNAL METHODS

These methods, although stable, are subject to change without notice.
Extend at your own risk, APIs may change in the future.

=head2 BUILD

Intercept a parameter with the key C<Member> amd store it in C<member_args>

=head2 model

Returns the C<current_collection>

=head2 _build_members

Build individual viewports for each member of the collection,

=head2 _build_member_args

Defaults to an empty HASH ref.

=head2 _build_member_class

Defaults to L<Reaction::UI::ViewPort::Object>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
