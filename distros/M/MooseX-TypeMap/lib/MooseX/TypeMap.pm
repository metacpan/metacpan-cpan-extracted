package MooseX::TypeMap;

use Moose 1.02;
use MooseX::TypeMap::Entry;
use Scalar::Util qw(refaddr blessed);
use MooseX::Types::Moose qw(ArrayRef HashRef);
use Moose::Util::TypeConstraints qw(find_type_constraint);
use namespace::clean -except => [qw( meta )];

our $VERSION = '0.003000';
$VERSION = eval $VERSION;

has type_entries => (
  traits => ['Array'],
  isa => ArrayRef['MooseX::TypeMap::Entry'],
  lazy => 1,
  builder => '_build_type_entries',
  handles => {
    'type_entries' => 'elements',
  }
);

has subtype_entries => (
  traits => ['Array'],
  isa => ArrayRef['MooseX::TypeMap::Entry'],
  lazy => 1,
  builder => '_build_subtype_entries',
  handles => {
    'subtype_entries' => 'elements',
  }
);

has _sorted_entries => (
  traits => ['Array'],
  isa => ArrayRef[ArrayRef['MooseX::TypeMap::Entry']],
  lazy => 1,
  init_arg => undef,
  builder => '_build__sorted_entries',
  handles => {
    '_sorted_entries' => 'elements',
  }
);

has _type_to_entry_cache => (
  is => 'ro',
  isa => HashRef['MooseX::TypeMap::Entry'],
  lazy => 1,
  init_arg => undef,
  builder => '_build__type_to_entry_cache',
);

sub _build_type_entries { [] }
sub _build_subtype_entries { [] }
sub _build__type_to_entry_cache { {} }

sub _build__sorted_entries {
  my $self = shift;

  my %subtypes;
  my %tc_entry_map;
  for my $entry ( $self->subtype_entries ) {
    my $entry_tc = $entry->type_constraint;
    my $entry_ident = refaddr $entry_tc;
    $subtypes{$entry_ident} = {};
    $tc_entry_map{$entry_ident} = $entry;

    for my $other ( $self->subtype_entries ) {
      my $other_tc = $other->type_constraint;
      if( $other_tc->is_subtype_of($entry_tc) ){
        $subtypes{$entry_ident}->{refaddr $other_tc} = undef;
      }
    }
  }
  my @sorted;
  while (keys %subtypes) {
    my @slot;
    for my $ident (keys %subtypes) {
      if (!keys %{ $subtypes{$ident} }) {
        delete $subtypes{$ident};
        push(@slot, $ident);
      }
    }

    map { delete @{$_}{@slot} } values %subtypes;
    push @sorted, [ @tc_entry_map{@slot} ];
  }
  return \@sorted;
}

#back compat for a year or so
around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;
  my $args = $class->$orig(@_);
  if( my $entries = delete $args->{entries} ){
    my @type_entries = @$entries;
    if( my $orig_type_entries = delete $args->{type_entries} ){
      push(@type_entries, @$orig_type_entries);
    }
    $args->{type_entries} = \@type_entries;
  }
  return $args;
};


sub clone_with_additional_entries {
  my($self, $additional) = @_;
  my @type_entries = $self->type_entries;
  if( defined $additional->{type_entries} ){
    push(@type_entries, @{$additional->{type_entries}});
  }
  my @subtype_entries = $self->subtype_entries;
  if( defined $additional->{subtype_entries} ){
    push(@subtype_entries, @{$additional->{subtype_entries}});
  }
  return $self->new(
    type_entries => \@type_entries,
    subtype_entries => \@subtype_entries
  );
}

sub find_matching_entry {
  my($self, $type_or_name) = @_;
  my $type = find_type_constraint($type_or_name) or return;
  $type = $type->__type_constraint
    if blessed($type) eq 'MooseX::Types::TypeDecorator';

  my $cache = $self->_type_to_entry_cache;
  my $type_ident = refaddr $type;
  if( exists $cache->{$type_ident} ){
    return $cache->{$type_ident} if defined $cache->{$type_ident};
    return;
  }

  for my $entry ($self->type_entries) {
    if( $entry->type_constraint->equals($type) ){
      return $cache->{$type_ident} = $entry;
    }
  }

  for my $family ($self->_sorted_entries) {
    for my $entry (@$family) {
      my $tc = $entry->type_constraint;
      if( $type->equals($tc) || $type->is_subtype_of($tc) ){
        return $cache->{$type_ident} = $entry;
      }
    }
  }
  $cache->{$type_ident} = undef;
  return;
}

sub has_entry_for {
  my($self, $type) = @_;
  return defined $self->find_matching_entry($type);
}

sub resolve  {
  my($self, $type) = @_;
  if( my $entry = $self->find_matching_entry($type) ){
    return $entry->data;
  }
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

MooseX::TypeMap - A type-constraint-to-data map

=head1 SYNOPSIS

    use MooseX::Types::Moose qw(Str Int Num Value);

    my $map = MooseX::TypeMap->new(
      type_entries => [
        MooseX::TypeMap::Entry->new(
          data => 'number',
          type_constraint => Num,
        )
      ],
      subtype_entries => [
        MooseX::TypeMap::Entry->new(
          data => 'string',
          type_constraint => Str,
        )
      ]
    );

    $map->resolve(Int); #returns 'string'
    $map->resolve(Num); #returns 'number'
    $map->resolve(Str); #returns 'string'
    $map->resolve(Value); #returns an undefined value

=head1 ATTRIBUTES

=head2 type_entries

=over 4

=item B<type_entries> - dereferencing reader

=item B<_build_entries> - builder, defaults to C<[]>

=back

An ArrayRef of L<Entry|MooseX::TypeMap::Entry> objects. These entry
objects will only match on L</resolve> when the type constraint given is equal
to the type constraint in the entry.

=head2 subtype_entries

=over 4

=item B<subtype_entries> - dereferencing reader

=item B<_build_subtype_entries> - builder, defaults to C<[]>

=back

An ArrayRef of L<Entry|MooseX::TypeMap::Entry> objects. These entry
objects will match on L</resolve> when the type constraint given is equal
to, or a sub-type of, the type constraint in the entry.

=head2 _sorted_entries

=over 4

=item B<_sorted_entries> - dereferencing reader

=item B<_build__sorted_entries> - builder

=back

A private attribute that mantains a sorted array of arrays of entries in the
order in which they will be looked at if there is no matching entry in C<entries>
This attribute can not be set from the constructor, has no public methods and is
only being documented for the benefit of future contributors.

=head1 METHODS

=head2 new

=over 4

=item B<arguments:> C<\%arguments>

=item B<return value:> C<$object_instance>

=back

Constructor.
Accepts the following keys: C<type_entries>, C<subtype_entries>.

=head2 clone_with_additional_types

=over 4

=item B<arguments:> C<\%arguments>

=item B<return value:> C<$object_instance>

=back

Clone the current typemap with additional C<type_entries> and
C<subtype_entries> and return the new instance which includes all the current
entries and the additional ones provided. If \%arguments is ommitted, type map
returned will be an identical clone of the invocant.

=head2 find_matching_entry

=over 4

=item B<arguments:> C<$type>

=items B<return value:> C<$entry>

=back

Will return the C<$entry> C<$type> resolves to, or an undefined value if no
matching entry is found.

=head2 has_entry_for

=over 4

=item B<arguments:> C<$type>

=items B<return value:> boolean C<$has_entry>

=back

Will return true if the given C<$type> resolves to an entry and false otherwise.

=head2 resolve

=over 4

=item B<arguments:> C<$type>

=items B<return value:> C<$data_from_matching_entry>

=back

Will find the closest matching entry for C<$type> and return the contents of
the entry's L<data|MooseX::TypeMap::Entry/data> attribute;

=head1 AUTHORS

=over 4

=item Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=item Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=item Guillermo Roditi E<lt>groditi@cpan.orgE<gt>

=back

=head1 AUTHORS, COPYRIGHT AND LICENSE

This software is copyright (c) 2008, 2009, 2010 by its authos as listed in the
L</AUTHORS> section.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
