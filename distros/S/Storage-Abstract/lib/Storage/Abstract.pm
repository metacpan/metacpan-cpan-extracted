package Storage::Abstract;
$Storage::Abstract::VERSION = '0.003';
use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

has param 'driver' => (
	coerce => (InstanceOf ['Storage::Abstract::Driver'])
		->plus_coercions(HashRef, q{ Storage::Abstract->load_driver($_) }),
	handles => [
		qw(
			store
			is_stored
			retrieve
			dispose
			list

			readonly
			set_readonly
		)
	],
);

around BUILDARGS => sub {
	my ($orig, $self, @raw_args) = @_;
	my %args;

	if (@raw_args == 1 && ref $raw_args[0] eq 'HASH') {
		%args = %{$raw_args[0]};
	}
	else {
		%args = @raw_args;
	}

	my %other_args = %args;
	%args = ();
	foreach my $base_key (qw(driver)) {
		$args{$base_key} = delete $other_args{$base_key};
	}

	if (!ref $args{driver}) {
		$args{driver} = {
			driver => $args{driver},
			%other_args,
		};
	}

	return $self->$orig(%args);
};

sub load_driver
{
	my ($class, @raw_args) = @_;
	my %args;

	if (@raw_args == 1 && ref $raw_args[0] eq 'HASH') {
		%args = %{$raw_args[0]};
	}
	else {
		%args = @raw_args;
	}

	my $driver = delete $args{driver};
	die 'driver is required in Storage::Abstract' unless defined $driver;

	my $name = ucfirst $driver;
	my $full_namespace;
	if ($name =~ /^\+/) {
		$full_namespace = substr $name, 1;
	}
	else {
		$full_namespace = "Storage::Abstract::Driver::$name";
	}

	(my $file_path = $full_namespace) =~ s{::}{/}g;
	require "$file_path.pm";
	return $full_namespace->new(%args);
}

1;

__END__

=head1 NAME

Storage::Abstract - Abstraction for file storage

=head1 SYNOPSIS

	use Storage::Abstract;

	my $storage = Storage::Abstract->new(
		driver => 'Directory',
		directory => '/my/directory',
	);

	my $all_filenames = $storage->list;
	$storage->store('some/file', 'local_filename');
	$storage->store('some/file', \'file_content');
	$storage->store('some/file', $open_filehandle);
	my $bool = $storage->is_stored('some/file');
	$storage->dispose('/some/file');

	# retrieving a file
	try {
		# $fh is always opened in '<:raw' mode
		my $fh = $storage->retrieve('some/file', \my %info);

		# if passed, %info is filled with extra properties of the file
		say $info{mtime};
	}
	catch ($e) {
		# errors are reported via exceptions
		if ($e isa 'Storage::Abstract::X::NotFound') {
			# not found
		}
		elsif ($e isa 'Storage::Abstract::X::PathError') {
			# file path is invalid
		}
		elsif ($e isa 'Storage::Abstract::X::HandleError') {
			# error opening Perl handle
		}
		elsif ($e isa 'Storage::Abstract::X::StorageError') {
			# error fetching file from storage
		}
	}


=head1 DESCRIPTION

This module lets you store and retrieve files from various places with a
unified API. Its main purpose is to abstract away file storage, so that you
only have to handle high-level operations without worrying about details.

B<BETA QUALITY>: The interface is not yet stable before version C<1.000>.

=head2 Drivers

When creating an instance of this module, you need to pass L</driver> and any
extra attributes that driver need. All implementation details depend on the
chosen driver, this module only contains methods which delegate to same methods
of the driver.

There are drivers and metadrivers. Metadrivers do not implement any file
storage by themselves, but rather change the way other storages work. The module
comes with the following driver implementations:

=over

=item * L<Storage::Abstract::Driver::Memory>

This driver keeps the files in Perl process memory as strings.

=item * L<Storage::Abstract::Driver::Directory>

This driver stores the files in a local machine's directory.

=item * L<Storage::Abstract::Driver::Composite>

This metadriver can be configured to keep a couple source storages at once and
use them all in sequence until it finds a file.

=item * L<Storage::Abstract::Driver::Subpath>

This metadriver is useful when you want to have a modify the base path of
another storage, to restrict access or adapt a path (for example for HTTP
public directory).

=item * L<Storage::Abstract::Driver::Null>

This driver does nothing - it won't store or retrieve anything.

=back

=head2 File paths

All file paths used in this module must be Unix-like regardless of the
platform. C</> is used as a directory separator, C<..> is used as an upward
directory, C<.> is used as a current directory (is ignored), and empty file
paths are ignored. Any platform-specific parts of file paths which are not
listed above are allowed and will not be recognized as path syntax. Drivers
which deal with platform-specific paths (for example
L<Storage::Abstract::Driver::Directory>) may raise an exception if path
contains any platform-specific syntax different from Unix syntax.

All file paths will be normalized, so that:

=over

=item

Empty parts will be removed, so C<a//b> will become C<a/b>. Because of this,
all paths will end up being relative (the leading C</> will be removed).

=item

Current directory written as C<.> will be removed, so C<./a> will become C<a>.

=item

Up directory written as C<..> will modify the path accordingly, so C<a/../b>
will become C<b>. If the path tries to leave the root, a
C<Storage::Abstract::X::PathError> will be raised.

=item

Last part of the path must look like a filename. Paths like C<a/>, C<a/.> or
C<a/..> will raise C<Storage::Abstract::X::PathError>.

=back

=head2 File handles

This module works with open filehandles in binary mode. These handles are
likely to be pointing at an in-memory scalar rather than a regular file, so they
are not guaranteed to work with C<sysread>/C<syswrite>. You may use C<fileno>
to check if a handle is pointing to an actual file.

If you pass a handle to L</store>, it should be properly marked as binary with
C<binmode> and should be rewinded to a point from which you want to store it
using C<seek> / C<sysseek>. The handle is sure to point at EOF after the module
is done copying it.

It is recommended to close the returned handles as soon as possible.

=head2 Properties

This module can get additional file data when retrieving files. It is similar
to calling C<stat> on a filehandle, but contains much less information.

Currently, only the following keys are guaranteed to be included for all drivers:

=over

=item * C<size>

The size of the data in the returned handle, in bytes.

=item * C<mtime>

Last modification unix timestamp of the file.

=back

=head1 INTERFACE

=head2 Attributes

All attributes not listed here will be used as extra attributes for
constructing the driver.

=head3 driver

B<Required> - This is the name of the driver to use. It must be a partial class
name from namespace C<Storage::Abstract::Driver::>, for example C<Directory>
will point to L<Storage::Abstract::Driver::Directory>. First letter of the
driver will be capitalized. If the name is prefixed with C<+>, the rest of the
name will be used as full namespace without adding the standard prefix, same as
in Plack.

After the object is created, this will point to an instance of the driver.
Alternatively, an already constructed driver object can be passed, and will be
used as-is.

=head2 Methods

These are common methods not dependant on a driver.

=head3 new

	$obj = Storage::Abstract->new(%args);
	$obj = Storage::Abstract->new(\%args);

Moose-flavoured constructor, but C<%args> will be used to construct the driver
rather than this class.

=head3 load_driver

	$driver_obj = Storage::Abstract->load_driver(%args);
	$driver_obj = Storage::Abstract->load_driver(\%args);

Loads the driver package and constructs the driver using C<%args> (same as in
the constructor). Returns an instance of L<Storage::Abstract::Driver>.

=head2 Delegated methods

These methods are delegates from the underlying instance of
L<Storage::Abstract::Driver>, stored in L</driver>. They may raise an exception
if the input is invalid or if they encounter an error.

Note that missing file will also be reported via an exception, not by returning
C<undef>.

=head3 store

	$obj->store($path, \$content)
	$obj->store($path, $filename)
	$obj->store($path, $handle)

Stores a new file in the storage under C<$path>. Does not return anything.

=head3 is_stored

	$bool = $obj->is_stored($path)

Checks whether a given C<$path> is stored in the storage. Returns true if it is.

=head3 retrieve

	$handle = $obj->retrieve($path, $properties = undef)

Returns a C<$handle> to a file stored under C<$path>.

If C<$properties> are passed, it must be a reference to a hash. This hash will
be filled with additional properties of the file, such as C<mtime>
(modification time).

=head3 dispose

	$obj->dispose($path)

Removes file C<$path> from the storage.

It treats missing files as an error, so if no exception occurs you can be sure
that the removal was performed.

=head3 list

	my $filenames_aref = $obj->list;

Lists the names of all files existing in the storage in an array reference.
These names will be forced to the normalized form.

This may be a costly operation (depending on the driver), so use it sparingly.

=head3 readonly

	$bool = $obj->readonly()

Returns true if the storage is readonly. Readonly storage will raise an
exception on L</store> and L</dispose>.

=head3 set_readonly

	$obj->set_readonly($bool)

Sets the readonly status of the storage to a new value.

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 ACKNOWLEDGEMENTS

Thank you to Alexander Karelas for his feedback during module development.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

