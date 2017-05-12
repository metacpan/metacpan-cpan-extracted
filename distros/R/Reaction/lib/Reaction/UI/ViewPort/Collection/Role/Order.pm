package Reaction::UI::ViewPort::Collection::Role::Order;

use Reaction::Role;

use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/Int HashRef Str ArrayRef/;
has enable_order_by => (is => 'rw', isa => ArrayRef);
has coerce_order_by => (is => 'rw', isa => HashRef);

has order_by => (
  isa => Str,
  is => 'rw',
  trigger_adopt('order_by'),
  clearer => 'clear_order_by'
);

has order_by_desc => (
  isa => Int,
  is => 'rw',
  trigger_adopt('order_by'),
  lazy_build => 1
);

sub _build_order_by_desc { 0 }

sub adopt_order_by {
  shift->clear_current_collection;
}

sub can_order_by {
  my ($self,$order_by) = @_;
  return 1 unless $self->has_enable_order_by;
  return scalar grep { $order_by eq $_ } @{ $self->enable_order_by };
}

sub _order_search_attrs {
  my $self = shift;
  my %attrs;
  if ($self->has_order_by) {
    my $order_by = $self->order_by;
    if( $self->has_coerce_order_by ){
      $order_by = $self->coerce_order_by->{$order_by}
        if exists $self->coerce_order_by->{$order_by};
    }
    my $key = $self->order_by_desc ? '-desc' : '-asc';
    $attrs{order_by} = { $key => $order_by };
  }
  return \%attrs;
}

after clear_order_by => sub {
  my ($self) = @_;
  $self->order_by_desc(0);
  $self->clear_current_collection;
};

around _build_current_collection => sub {
  my $orig = shift;
  my ($self) = @_;
  my $collection = $orig->(@_);
  return $collection->where(undef, $self->_order_search_attrs);
};

around accept_events => sub { ('order_by', 'order_by_desc', shift->(@_)); };

1;

__END__;

=head1 NAME

Reaction::UI::ViewPort::Collection::Role::Order - Order support for collections

=head1 DESCRIPTION

Role to add order support to collection viewports.

=head1 ATTRIBUTES

=head2 enable_order_by

Re-writable array reference. Optionally use this to manually specify a list of
fields that support ordering, instead of the default of all fields. This is
useful to exclude computed values or non-indexed columns from being sortable.

=head2 coerce_order_by

Re-writeable hash reference. Optionally use this to manually specify the way in
which a field should be ordered. This is useful when the field name and the
query to sort it differ. E.g. for a belongs_to item:

    coerce_order_by => { foo => ['foo.last_name', 'foo.first_name'] },

=head2  order_by

Re-writeable string. Optionally set it to dictate which field to use when
sorting.

=head2 order_by_desc

Re-writeable boolean. Optionally use descending order when sorting. Defaults to false.

=head1 METHODS

=head2 can_order_by $field_name

Returns true if sorting by that field is supported, false otherwise.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
