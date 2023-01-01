use strict;
use warnings;

package Mixin::ExtraFields::Driver::HashGuts 0.140003;
use parent qw(Mixin::ExtraFields::Driver);
# ABSTRACT: store extras in a hashy object's guts

#pod =head1 SYNOPSIS
#pod
#pod   package Your::HashBased::Class;
#pod
#pod   use Mixin::ExtraFields -fields => { driver => 'HashGuts' };
#pod
#pod =head1 DESCRIPTION
#pod
#pod This driver class implements an extremely simple storage mechanism: extras are
#pod stored on the object on which the mixed-in methods are called.  By default,
#pod they are stored under the key returned by the C<L</default_has_key>> method,
#pod but this can be changed by providing a C<hash_key> argument to the driver
#pod configuration, like so:
#pod
#pod   use Mixin::ExtraFields -fields => {
#pod     driver => { class => 'HashGuts', hash_key => "\0Something\0Wicked\0" }
#pod   };
#pod
#pod =head1 METHODS
#pod
#pod In addition to the methods required by Mixin::ExtraFields::Driver, the
#pod following methods are provided:
#pod
#pod =head2 hash_key
#pod
#pod   my $key = $driver->hash_key;
#pod
#pod This method returns the key where the driver will store its extras.
#pod
#pod =cut

sub hash_key {
  my ($self) = @_;
  return $self->{hash_key};
}

#pod =head2 default_hash_key
#pod
#pod If no C<hash_key> argument is given for the driver, this method is called
#pod during driver initialization.  It will return a unique string to be used as the
#pod hash key.
#pod
#pod =cut

my $i = 0;
sub default_hash_key {
  my ($self) = @_;
  return "$self" . '@' . $i++;
}

#pod =head2 storage
#pod
#pod This method returns the hashref of storage used for extras.  Individual objects
#pod get weak references to their id within this hashref.
#pod
#pod =cut

sub storage { $_[0]->{storage} }

#pod =head2 storage_for
#pod
#pod   my $stash = $driver->storage_for($object, $id);
#pod
#pod This method returns the hashref to use to store extras for the given object and
#pod id.  This hashref is stored on both the hash-based object (in its C<hash_key>
#pod entry) and on the driver (in the entry for C<$id> in its C<storage> hash).
#pod
#pod All objects with the same id should end up with the same hash in their
#pod C<hash_key> field.  B<None> of these references are weakened, which means two
#pod things:  first, even if all objects with a given id go out of scope, future
#pod objects with that id will retain the original extras; secondly, memory used to
#pod store extras is never reclaimed.  If this is a problem, use a more
#pod sophisticated driver.
#pod
#pod =cut

sub storage_for {
  my ($self, $object, $id) = @_;

  my $store = $self->storage->{ $id } ||= {};

  unless ($object->{ $self->hash_key }||0 == $store) {
    $object->{ $self->hash_key } ||= $store;
  }

  return $store
}

sub from_args {
  my ($class, $arg) = @_;

  my $self = bless { storage => {} } => $class;

  $self->{hash_key} = $arg->{hash_key} || $self->default_hash_key;

  return $self;
}

sub exists_extra {
  my ($self, $object, $id, $name) = @_;

  return exists $self->storage_for($object, $id)->{$name};
}

sub get_extra {
  my ($self, $object, $id, $name) = @_;

  # avoid autovivifying entries on get.
  return unless $self->exists_extra($object, $id, $name);
  return $self->storage_for($object, $id)->{$name};
}

sub get_detailed_extra {
  my ($self, $object, $id, $name) = @_;

  # avoid autovivifying entries on get.
  return unless $self->exists_extra($object, $id, $name);
  return { value => $self->storage_for($object, $id)->{$name} };
}

sub get_all_detailed_extra {
  my ($self, $object, $id) = @_;

  my $stash = $self->storage_for($object, $id);
  my @all_detailed = map { $_ => { value => $stash->{$_} } } keys %$stash;
}

sub get_all_extra {
  my ($self, $object, $id) = @_;

  return %{ $self->storage_for($object, $id) };
}

sub set_extra {
  my ($self, $object, $id, $name, $value) = @_;

  $self->storage_for($object, $id)->{$name} = $value;
}

sub delete_extra {
  my ($self, $object, $id, $name) = @_;

  delete $self->storage_for($object, $id)->{$name};
}

sub delete_all_extra {
  my ($self, $object, $id) = @_;
  %{ $self->storage_for($object, $id) } = ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mixin::ExtraFields::Driver::HashGuts - store extras in a hashy object's guts

=head1 VERSION

version 0.140003

=head1 SYNOPSIS

  package Your::HashBased::Class;

  use Mixin::ExtraFields -fields => { driver => 'HashGuts' };

=head1 DESCRIPTION

This driver class implements an extremely simple storage mechanism: extras are
stored on the object on which the mixed-in methods are called.  By default,
they are stored under the key returned by the C<L</default_has_key>> method,
but this can be changed by providing a C<hash_key> argument to the driver
configuration, like so:

  use Mixin::ExtraFields -fields => {
    driver => { class => 'HashGuts', hash_key => "\0Something\0Wicked\0" }
  };

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

In addition to the methods required by Mixin::ExtraFields::Driver, the
following methods are provided:

=head2 hash_key

  my $key = $driver->hash_key;

This method returns the key where the driver will store its extras.

=head2 default_hash_key

If no C<hash_key> argument is given for the driver, this method is called
during driver initialization.  It will return a unique string to be used as the
hash key.

=head2 storage

This method returns the hashref of storage used for extras.  Individual objects
get weak references to their id within this hashref.

=head2 storage_for

  my $stash = $driver->storage_for($object, $id);

This method returns the hashref to use to store extras for the given object and
id.  This hashref is stored on both the hash-based object (in its C<hash_key>
entry) and on the driver (in the entry for C<$id> in its C<storage> hash).

All objects with the same id should end up with the same hash in their
C<hash_key> field.  B<None> of these references are weakened, which means two
things:  first, even if all objects with a given id go out of scope, future
objects with that id will retain the original extras; secondly, memory used to
store extras is never reclaimed.  If this is a problem, use a more
sophisticated driver.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
