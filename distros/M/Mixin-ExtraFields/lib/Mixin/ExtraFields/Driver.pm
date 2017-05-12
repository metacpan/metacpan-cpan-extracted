
use strict;
use warnings;

package Mixin::ExtraFields::Driver;
{
  $Mixin::ExtraFields::Driver::VERSION = '0.140002';
}
# ABSTRACT: a backend for extra field storage

use Carp ();
use Sub::Install ();


BEGIN {
  for my $name (qw(from_args get_all_detailed_extra set_extra delete_extra)) {
    Sub::Install::install_sub({
      as   => $name,
      code => sub { Carp::confess "method $name called but not implemented!" },
    });
  }
}


sub get_all_extra {
  my ($self, $object, $id) = @_;
  
  my %extra  = $self->get_all_detailed_extra($object, $id);
  my @simple = map { $_ => $extra{$_}{value} } keys %extra;
}


sub get_extra {
  my ($self, $object, $id, $name) = @_;
  
  my $extra = $self->get_detailed_extra($object, $id, $name);
  return $extra ? $extra->{value} : ();
}

sub get_detailed_extra {
  my ($self, $object, $id, $name) = @_;

  my %extra = $self->get_all_detailed_extra($object, $id);
  return exists $extra{$name} ? $extra{$name} : ();
}


sub get_all_extra_names {
  my ($self, $object, $id) = @_;
  my %extra = $self->get_all_detailed_extra($object, $id);
  return keys %extra;
}


sub exists_extra {
  my ($self, $object, $id, $name) = @_;
  my %extra = $self->get_all_detailed_extra($object, $id);

  return exists $extra{ $name };
}


sub delete_all_extra {
  my ($self, $object, $id) = @_;

  for my $name ($self->get_all_extra_names($object, $id)) {
    $self->delete_extra($object, $id, $name);
  }
}

1;

__END__

=pod

=head1 NAME

Mixin::ExtraFields::Driver - a backend for extra field storage

=head1 VERSION

version 0.140002

=head1 SYNOPSIS

This is really not something you'd use on your own, it's just used by
Mixin::ExtraFields, but if you insist...

  my $driver = Mixin::ExtraFields::Driver::Phlogiston->from_args(\%arg);

  $driver->set($obj, $obj_id, flammable => "very!");

=head1 DESCRIPTION

Mixin::ExtraFields::Driver is a base class for drivers used by
Mixin::ExtraFields -- hence the name.  A driver is expected to store and
retrieve data keyed to an object and a name or key.  It can store this in any
way it likes, and does not need to guarantee persistence across processes.

=head1 SUBCLASSING

All drivers must implement the four methods listed below.  The base class has
implementations of these methods which will die noisily (C<confess>-ing) when
called.

Almost all methods are passed the same data as their first two arguments:
C<$object>, the object for which the driver is to find or alter data, and
C<$id>, that object's unique id.  While this may be slighly redundant, it keeps
the id-finding call in one place.

=head2 from_args

  my $driver = Mixin::ExtraFields::Driver::Subclass->from_args(\%arg);

This method must return a driver object appropriate to the given args.  It is
not called C<new> because it need not return a new object for each call to it.
Returning identical objects for identical configurations may be safe for some
driver implementations, and it is expressly allowed.

The arguments passed to this method are those given as the C<driver> option to
the C<fields> import group in Mixin::ExtraFields, less the C<class> option.

=head2 get_all_detailed_extra

  my %extra = $driver->get_all_detailed_extra($object, $id);

This method must return all available information about all existing extra
fields for the given object.  It must be returned as a list of name/value
pairs.  The values must be references to hashes.  Each hash must have an entry
for the key C<value> giving the value for that name.

=head2 set_extra

  $driver->set_extra($object, $id, $name, $value);

This method must set the named extra to the given value.

=head2 delete_extra

  $driver->delete_extra($object, $id, $name);

This method must delete the named extra, causing it to cease to exist.

=head1 OPTIMIZING

The methods below can all be implemented in terms of those above.  If they are
not provided by the subclass, basic implementations exist.  These
implementations may be less efficient than implementations crafted for the
specifics of the storage engine behind the driver, so authors of driver
subclasses should consider implementing these methods.

=head2 get_all_extra

  my %extra = $driver->get_all_extra($object, $id);

This method behaves like C<get_all_detailed_extra>, above, but provides the
entry's value, not a detailed hashref, as the value for each entry.

=head2 get_extra

=head2 get_detailed_extra

  my $value = $driver->get_extra($object, $id, $name);

  my $hash = $driver->get_detailed_extra($object, $id, $name);

These methods return a single value requested by name, either as the value
itself or a detailed hashref describing it.

=head2 get_all_extra_names

  my @names = $driver->get_all_extra_names($object, $id);

This method returns the names of all existing extras for the given object.

=head2 exists_extra

  if ($driver->exists_extra($object, $id, $name)) { ... }

This method returns true if an entry exists for the given name and false
otherwise.

=head2 delete_all_extra

  $driver->delete_all_extra($object, $id);

This method deletes all extras for the object, as per the C<delete_extra>
method.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
