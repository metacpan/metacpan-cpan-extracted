package Storage::Abstract::Driver;
$Storage::Abstract::Driver::VERSION = '0.007';
use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

use Scalar::Util qw(blessed);
use Storage::Abstract::Handle;
use Storage::Abstract::X;

# Not using File::Spec here, because paths must be unix-like regardless of
# local OS
use constant UPDIR_STR => '..';
use constant CURDIR_STR => '.';
use constant DIRSEP_STR => '/';

has param 'readonly' => (
	isa => Bool,
	writer => 1,
	lazy => 1,
	clearer => -hidden,
);

# HELPERS

# this is intentionally not portable - only drivers working on an actual
# filesystem should port this unix-like path to its own representation
sub resolve_path
{
	my ($self, $name) = @_;

	my @path = split DIRSEP_STR, $name, -1;
	Storage::Abstract::X::PathError->raise("path $name is empty")
		if !@path;

	my $i = 0;
	my $last_ok = 1;
	while ($i < @path) {
		if ($path[$i] eq UPDIR_STR) {
			Storage::Abstract::X::PathError->raise("path $name is trying to leave root")
				if $i == 0;

			splice @path, $i - 1, 2;
			$last_ok = 0;
			$i -= 1;
		}
		elsif ($path[$i] eq '' || $path[$i] eq CURDIR_STR) {
			splice @path, $i, 1;
			$last_ok = 0;
		}
		else {
			$i += 1;
			$last_ok = 1;
		}
	}

	Storage::Abstract::X::PathError->raise("path $name has no filename")
		unless $last_ok;

	return join DIRSEP_STR, @path;
}

sub common_properties
{
	my ($self, $handle) = @_;

	return {
		size => tied(*$handle)->size,
		mtime => time,
	};
}

sub refresh
{
	# Nothing to clear here
}

# TO BE IMPLEMENTED IN SUBCLASSES

sub store_impl
{
	my ($self, $name, $handle) = @_;

	...;
}

sub is_stored_impl
{
	my ($self, $name) = @_;

	...;
}

sub retrieve_impl
{
	my ($self, $name, $properties) = @_;

	...;
}

sub dispose_impl
{
	my ($self, $name, $handle) = @_;

	...;
}

sub list_impl
{
	my ($self) = @_;

	...;
}

# PUBLIC INTERFACE

sub store
{
	my ($self, $name, $handle) = @_;
	local $Storage::Abstract::X::path_context = $name;

	Storage::Abstract::X::Readonly->raise('storage is readonly')
		if $self->readonly;

	$self->store_impl($self->resolve_path($name), $handle);
	return;
}

sub is_stored
{
	my ($self, $name) = @_;
	local $Storage::Abstract::X::path_context = $name;

	return $self->is_stored_impl($self->resolve_path($name));
}

sub retrieve
{
	my ($self, $name, $properties) = @_;
	local $Storage::Abstract::X::path_context = $name;

	return $self->retrieve_impl($self->resolve_path($name), $properties);
}

sub dispose
{
	my ($self, $name) = @_;
	local $Storage::Abstract::X::path_context = $name;

	Storage::Abstract::X::Readonly->raise('storage is readonly')
		if $self->readonly;

	$self->dispose_impl($self->resolve_path($name));
	return;
}

sub list
{
	my ($self) = @_;

	return $self->list_impl;
}

1;

__END__

=head1 NAME

Storage::Abstract::Driver - Base class for drivers

=head1 SYNOPSIS

	package Storage::Abstract::Driver::MyDriver;

	use Moo;
	extends 'Storage::Abstract::Driver';

	# consume one of those roles
	with 'Storage::Abstract::Role::Driver::Basic';
	with 'Storage::Abstract::Role::Driver::Meta';

	# these methods need implementing
	sub store_impl { ... }
	sub is_stored_impl { ... }
	sub retrieve_impl { ... }
	sub dispose_impl { ... }
	sub list_impl { ... }

=head1 DESCRIPTION

This class contains the interface of handling files via Storage::Abstract (as
discussed in L<Storage::Abstract/Delegated methods>), a couple of unimplemented
methods which must be implemented in the subclasses, and a couple of helpers
which may be used or reimplemented in the subclasses when needed.

This class should never be instantiated directly. Its subclasses should consume
one of the roles, either L<Storage::Abstract::Role::Driver::Basic> or
L<Storage::Abstract::Role::Driver::Meta>.

=head1 INTERFACE

=head2 Attributes

These attributes are common to all drivers.

=head3 readonly

Boolean - whether this driver is readonly. False by default. May be changed
using C<set_readonly>.

This attribute is not applicable to meta drivers. This type of drivers don't
store its own readonly status, so this attribute is used as a cache for the
underlying drivers C<readonly> status. Calling C<set_readonly> on meta drivers
will call C<set_readonly> of the underlying driver and refresh the cache. If
the meta driver holds more than one source (for example
L<Storage::Abstract::Driver::Composite>), calling C<set_readonly> will throw an
exception.

=head2 Helper methods

These methods may be used by drivers to make implementation easier.

=head3 resolve_path

	$path = $obj->resolve_path($path)

This normalizes the path as discussed in L<Storage::Abstract/File paths>. It is
guaranteed to be called automatically every time one of the delegated methods
is called, before the path is used for anything. As such, it can be
reimplemented in a driver class to modify its behavior (see
L<Storage::Abstract::Driver::Directory> for an example).

=head3 common_properties

	my $properties = $obj->common_properties($handle);

This returns a hash reference containing a list of properties with default
values. Note that this does not get all these properties from C<$handle>, but
instead produces a new list of properties for drivers which must create it
themselves (like L<Storage::Abstract::Driver::Memory>).

=head2 Implementation methods

These methods must be reimplemented in driver classes:

=over

=item * C<store_impl>

	store_impl($path, $fh)

The implementation of storing a new file in the storage. It will be passed a
normalized path and an open file handle. For drivers implementing
L<Storage::Abstract::Role::Driver::Basic>, C<$fh> will be a tied object of
L<Storage::Abstract::Handle>.

Its return value will be ignored.

=item * C<is_stored_impl>

	is_stored_impl($path)

The implementation of checking whether a file is stored. It will be passed a
normalized path. Must return a boolean.

=item * C<retrieve_impl>

	retrieve_impl($path, \%properties)

The implementation of retrieving a file. First argument is a normalized path.
Second argument may be C<undef>, but when it is defined, it will be a hash
reference to put extra properties of the file into. Drivers may optimize not to
fetch properties when the second argument is undefined (if such optimization is
possible). Every driver should include at least the same keys as returned by
L</common_properties>.

Basic drivers should not check C<is_stored> - it will never be called without checking
C<is_stored> first. Must return an open file handle to the file. The file
handle should be rewound to the beginning (ready to be read without calling
C<seek>) and it should read data into memory lazily regardless of the
underlying storage type. It is recommended that the file handle is a tied
object of L<Storage::Abstract::Handle> or its subclass. Calling
C<retrieve_impl> by itself should not cause the storage to perform any IO
operations, so that it can be used just to fetch C<%properties> efficiently.

=item * C<dispose_impl>

	dispose_impl($path)

The implementation of disposing a file. First argument is a normalized path.

Basic drivers should not check C<is_stored> - it will never be called without checking
C<is_stored> first. Its return value will be ignored.

=item * C<list_impl>

	list_impl($path)

The implementation of getting a list of files. Should return an array reference
with file names (in Unix format).

=back

