package Storage::Abstract::Driver;
$Storage::Abstract::Driver::VERSION = '0.003';
use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

use Scalar::Util qw(blessed);
use Storage::Abstract::X;

# Not using File::Spec here, because paths must be unix-like regardless of
# local OS
use constant UPDIR_STR => '..';
use constant CURDIR_STR => '.';
use constant DIRSEP_STR => '/';

has param 'readonly' => (
	writer => 1,
	isa => Bool,
	default => !!0,
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

sub open_handle
{
	my ($self, $arg) = @_;
	return $arg
		if blessed $arg && $arg->isa('IO::Handle');

	open my $fh, '<:raw', $arg
		or Storage::Abstract::X::HandleError->raise((ref $arg ? '' : "$arg: ") . $!);

	return $fh;
}

sub copy_handle
{
	my ($self, $handle_from, $handle_to) = @_;

	# no extra behavior of print
	local $\;

	my $read = sub { read $_[0], $_[1], 8 * 1024 };
	my $write = sub { print {$_[0]} $_[1] };

	# can use sysread / syswrite?
	if (fileno $handle_from != -1 && fileno $handle_to != -1) {
		$read = sub { sysread $_[0], $_[1], 128 * 1024 };
		$write = sub {
			my $written = 0;
			while ($written < $_[2]) {
				my $res = syswrite $_[0], $_[1], $_[2], $written;
				return undef unless defined $res;
				$written += $res;
			}

			return 1;
		};
	}

	my $buffer;
	while ('copying') {
		my $bytes = $read->($handle_from, $buffer);

		Storage::Abstract::X::HandleError->raise("error reading from handle: $!")
			unless defined $bytes;
		last if $bytes == 0;
		$write->($handle_to, $buffer, $bytes)
			or Storage::Abstract::X::StorageError->raise("error during file copying: $!");
	}
}

sub common_properties
{
	my ($self, $handle) = @_;
	my $size = do {
		if (fileno $handle == -1) {
			my $success = (my $pos = tell $handle) >= 0;
			$success &&= seek $handle, 0, 2;
			$success &&= (my $res = tell $handle) >= 0;
			$success &&= seek $handle, $pos, 0;

			$success or Storage::Abstract::X::HandleError->raise($!);
			$res;
		}
		else {
			-s $handle;
		}
	};

	return {
		size => $size,
		mtime => time,
	};
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

	if (ref $handle ne 'GLOB') {
		Storage::Abstract::X::HandleError->raise('handle argument is not defined')
			unless defined $handle;

		$handle = $self->open_handle($handle);
	}

	Storage::Abstract::X::StorageError->raise('storage is readonly')
		if $self->readonly;

	$self->store_impl($self->resolve_path($name), $handle);
	return;
}

sub is_stored
{
	my ($self, $name) = @_;

	return $self->is_stored_impl($self->resolve_path($name));
}

sub retrieve
{
	my ($self, $name, $properties) = @_;
	my $path = $self->resolve_path($name);

	Storage::Abstract::X::NotFound->raise("file $name was not found")
		unless $self->is_stored_impl($path);

	return $self->retrieve_impl($path, $properties);
}

sub dispose
{
	my ($self, $name) = @_;

	Storage::Abstract::X::StorageError->raise('storage is readonly')
		if $self->readonly;

	my $path = $self->resolve_path($name);

	Storage::Abstract::X::NotFound->raise("file $name was not found")
		unless $self->is_stored_impl($path);

	$self->dispose_impl($path);
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

	# these methods need implementing
	sub store_impl { ... }
	sub is_stored_impl { ... }
	sub retrieve_impl { ... }
	sub dispose_impl { ... }

=head1 DESCRIPTION

This class contains the interface of handling files via Storage::Abstract (as
discussed in L<Storage::Abstract/Delegated methods>), a couple of unimplemented
methods which must be implemented in the subclasses, and a couple of helpers
which may be used or reimplemented in the subclasses when needed.

This class should never be instantiated directly.

=head1 INTERFACE

=head2 Attributes

These attributes are common to all drivers.

=head3 readonly

Boolean - whether this driver is readonly. False by default. May be changed
using C<set_readonly>.

=head2 Helper methods

These methods may be used by drivers to make implementation easier.

=head3 resolve_path

	$path = $obj->resolve_path($path)

This normalizes the path as discussed in L<Storage::Abstract/File paths>. It is
guaranteed to be called automatically every time one of the delegated methods
is called, before the path is used for anything. As such, it can be
reimplemented in a driver class to modify its behavior (see
L<Storage::Abstract::Driver::Directory> for an example).

=head3 open_handle

	$fh = $obj->open_handle(\$content);
	$fh = $obj->open_handle($filename);

This tries to create a readonly, binary handle from its argument. It will not
do anything if the argument is a class of L<IO::Handle>.

=head3 copy_handle

	$obj->copy_handle($fh_from, $fh_to)

This copies the data from C<$fh_from> to C<$fh_to>. Based on the C<fileno>
result on the handles, it uses either C<sysread> + C<syswrite> or C<read> +
C<print>. Use this to move data between filehandles in driver classes.

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
normalized path and an opened file handle. Its return value will be ignored.

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

It should not check C<is_stored> - it will never be called without checking
C<is_stored> first. Must return an opened file handle to the file.

=item * C<dispose_impl>

	dispose_impl($path)

The implementation of disposing a file. First argument is a normalized path.

It should not check C<is_stored> - it will never be called without checking
C<is_stored> first. Its return value will be ignored.

=item * C<list_impl>

	list_impl($path)

The implementation of getting a list of files. Should return an array reference
with file names (in Unix format).

=back

