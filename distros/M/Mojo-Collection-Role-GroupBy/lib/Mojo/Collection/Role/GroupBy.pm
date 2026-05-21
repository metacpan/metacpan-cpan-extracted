use strict;
use warnings;

package Mojo::Collection::Role::GroupBy;

use Role::Tiny;
use List::Util qw/uniq/;
use Hash::Util::FieldHash qw/fieldhash/;
use Carp;
use Exporter 'import';
use Mojo::Collection::Role::GroupBy::Util qw/pack_array unpack_array/;

# ABSTRACT: adds group_by function to Mojo::Collection

our $VERSION = '0.003';

requires 'each';

fieldhash my %is_grouped;
fieldhash my %is_composite;

sub _is_grouped {
    my $self = shift;
    if (@_){ $is_grouped{$self} = shift }
    return $is_grouped{$self}
}

sub _is_composite {
    my $self = shift;
    if (@_){ $is_composite{$self} = shift }
    return $is_composite{$self}
}

sub _group {
    my ($self, $group_sub) = @_;

    my ($composite, $sub) = $self->_make_group_sub($group_sub);
    my %h;
    $self->each(sub {
        my $v = shift;
        my $k = $sub->($v);
        push @{$h{$k}}, $v;
    });
    return ($composite, \%h);
    # return %h;
}

sub _type {
    my $self = shift;
    my %seen;
    for ($self->@*) {
        my $t = ref $_ eq 'ARRAY' ? 'ARRAY'
              : ref $_ eq 'HASH'  ? 'HASH'
              : blessed $_        ? 'OBJECT'
              :                     'SCALAR';
        $seen{$t}++;
    }
    die "Mixed collection: contains " . join(", ", keys %seen) . "\n" if keys %seen > 1;
    return (keys %seen)[0];
}


sub _make_group_sub {
    my ($self, @args) = @_;
    return (0, $args[0]) if ref $args[0] eq 'CODE';

    my $type = $self->_type();

    my $arg; 
    if (@args == 1 && !ref $args[0]) {
	$arg = $args[0]
    }
    elsif (ref $args[0] eq "ARRAY" && scalar $args[0]->@* == 1) {
	$arg = $args[0]->[0]
    }
    elsif (ref $args[0] eq "ARRAY") {
	@args = $args[0]->@*
    }
    elsif (@args > 1) {
	# already fine, @args is set
    }
    else {
	croak "Arguments must be scalars or an arrayref"
    }

    if (defined $arg) {
        return (0, sub { ${$_[0]}[$arg] })  if $type eq 'ARRAY';
        return (0, sub { ${$_[0]}{$arg} })  if $type eq 'HASH';
        return (0, sub { $_[0]->$arg })    if $type eq 'OBJECT';
    }
    else {
	if ($type eq 'ARRAY') { return (1, sub { pack_array( map { $_[0]->[$_] } @args ) }); }
	if ($type eq 'HASH') { return (1, sub { pack_array( map { $_[0]->{$_} } @args ) }); }
	return (1, sub { pack_array( map { $_[0]->$_ } @args ) });
    }
}

sub group_by {
    my ($self, $group_sub) = @_;

    my ($composite, $h) = $self->_group($group_sub);
    my %h = $h->%*;

    $self = $self->new(map { [ $_, $self->new($h{$_}->@*) ] } sort keys %h);

    $self->_is_grouped(1);
    $self->_is_composite($composite);

    return $self;
}

sub to_hash {
    my ($self, $group_sub) = @_;
    my $composite;
    my %h;
    unless ($group_sub) {
	die "This does not look like a grouped Mojo::Collection\n" unless $self->_is_grouped;
	$self->each(sub { $h{$_->[0]} = $_->[1] });
    }
    else {
	%h = $self->_group($group_sub)->%*;
    }
    $_ = Mojo::Collection->new($_->@*) for values %h;
    return \%h;
}

sub to_grouped_array {
    my ($self, $group_sub) = @_;
    my $h = $self->to_hash($group_sub);
    return [ map { $h->{$_} } sort keys $h->%* ]
}

sub expand {
    my $self = shift;
    my $composite = $self->_is_composite;
    my $h = $self->to_hash;

    return Mojo::Collection->new(
				 $self->_is_composite ?
				 map {
				     [ unpack_array($_) , $h->{$_} ]
				 } sort keys $h->%*
				 :
				 map {
				     [ $_, $h->{$_} ]
				 } sort keys $h->%*
				 )
}

1;


=encoding utf8

=head1 NAME

Mojo::Collection::Role::GroupBy - Group-by operations for Mojo::Collection

=head1 SYNOPSIS

  use Mojo::Collection;

  my $c = Mojo::Collection->new(
      [0, "a"], [1, "b"], [2, "a"]
  )->with_roles('+GroupBy');

  # Group by index
  my $grouped = $c->group_by(1);

  # Group by coderef
  my $grouped = $c->group_by(sub { $_[0]->[0] % 2 });

  # Group by multiple keys (composite)
  my $grouped = $c->group_by([0, 1]);

  # Convert to hash
  my $hash = $grouped->to_hash;

  # Expand to collection of key/value pairs
  my $expanded = $grouped->expand;

=head1 DESCRIPTION

L<Mojo::Collection::Role::GroupBy> is a role for L<Mojo::Collection> that adds
grouping operations. It can be applied to any L<Mojo::Collection> instance using
L<Mojo::Base/"with_roles">.

  my $c = Mojo::Collection->new(...)->with_roles('+GroupBy');

Collection elements can be arrayrefs, hashrefs, or objects. Mixed collections
will raise an error.

=head1 METHODS

L<Mojo::Collection::Role::GroupBy> implements the following methods.

=head2 group_by

  my $grouped = $c->group_by(sub { ... });
  my $grouped = $c->group_by($index);
  my $grouped = $c->group_by($key);
  my $grouped = $c->group_by([$key1, $key2]);
  my $grouped = $c->group_by($key1, $key2);

Group collection elements by the return value of a grouping function. Returns a
new L<Mojo::Collection> of C<[$key, $collection]> pairs sorted by key.

The grouping argument can be a coderef, a scalar index or key, or an arrayref
of indices or keys for composite grouping.

  # Group arrayrefs by element at index 1
  my $grouped = $c->group_by(1);

  # Group hashrefs by key
  my $grouped = $c->group_by('category');

  # Group objects by method
  my $grouped = $c->group_by('name');

  # Group by multiple keys
  my $grouped = $c->group_by([0, 1]);

  # Group with a coderef
  my $grouped = $c->group_by(sub { $_[0]->[0] % 2 });

=head2 to_hash

  my $hash = $grouped->to_hash;
  my $hash = $c->to_hash(sub { ... });
  my $hash = $c->to_hash($key);

Convert a grouped collection to a hashref, or group and convert in one step by
passing a grouping argument. Values are L<Mojo::Collection> objects.

  # Group first, then convert
  my $hash = $c->group_by('category')->to_hash;

  # Group and convert in one step
  my $hash = $c->to_hash('category');

=head2 to_grouped_array

  my $array = $grouped->to_grouped_array;
  my $array = $c->to_grouped_array(sub { ... });

Convert a grouped collection to an arrayref of collections, sorted by key.

=head2 expand

  my $expanded = $grouped->expand;

Expand a grouped collection into a new L<Mojo::Collection> of C<[$key, $collection]>
pairs, where C<$key> is the plain grouping key. For composite keys, C<$key> is
an arrayref of the component values.

  my $expanded = $c->group_by(1)->expand;
  $expanded->each(sub {
      my ($key, $values) = $_->@*;
      say "Group $key has " . $values->size . " elements";
  });

  # Composite keys come back as arrayrefs
  my $expanded = $c->group_by([0, 1])->expand;
  $expanded->each(sub {
      my ($keys, $values) = $_->@*;
      say join(", ", @$keys);
  });

=head1 ERRORS

L<Mojo::Collection::Role::GroupBy> will raise an error if the collection
contains mixed element types (arrayrefs, hashrefs, and objects cannot be
mixed), or if L</"to_hash"> or L</"expand"> are called on an ungrouped
collection without a grouping argument.

=head1 SEE ALSO

L<Mojo::Collection>, L<Mojo::Base>, L<Mojo::Collection::Role::GroupBy::Util>

=head1 AUTHOR

Simone Cesano <scesano@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Simone Cesano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
