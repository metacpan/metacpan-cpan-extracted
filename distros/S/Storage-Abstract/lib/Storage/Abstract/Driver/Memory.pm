package Storage::Abstract::Driver::Memory;
$Storage::Abstract::Driver::Memory::VERSION = '0.002';
use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

extends 'Storage::Abstract::Driver';

has field 'files' => (
	isa => HashRef,
	default => sub { {} },
);

sub store_impl
{
	my ($self, $name, $handle) = @_;
	my $files = $self->files;

	$files->{$name}{properties} = $self->common_properties($handle);

	open my $fh, '>:raw', \$files->{$name}{content}
		or Storage::Abstract::X::StorageError->raise("Could not open storage: $!");

	$self->copy_handle($handle, $fh);

	close $fh
		or Storage::Abstract::X::StorageError->raise("Could not close handle: $!");
}

sub is_stored_impl
{
	my ($self, $name) = @_;

	return exists $self->files->{$name};
}

sub retrieve_impl
{
	my ($self, $name, $properties) = @_;
	my $files = $self->files;

	if ($properties) {
		%{$properties} = %{$files->{$name}{properties}};
	}

	return $self->open_handle(\$files->{$name}{content});
}

sub dispose_impl
{
	my ($self, $name) = @_;

	delete $self->files->{$name};
}

sub list_impl
{
	my ($self) = @_;

	return [keys %{$self->files}];
}

1;

__END__

=head1 NAME

Storage::Abstract::Driver::Memory - In-memory storage of files

=head1 SYNOPSIS

	my $storage = Storage::Abstract->new(
		driver => 'memory',
	);

=head1 DESCRIPTION

This driver will store entire files in Perl process memory. As such, it is most
suitable to use for testing or as a cache of small files.

=head2 Using as a snapshot of a directory

If you want to store just a couple of known files faster than direct disk
access, you can make use of dynamic C<readonly>:

	$storage->set_readonly(0);
	$storage->store('path1', 'file1');
	$storage->store('path2', 'file2');
	$storage->set_readonly(1);

=head1 CUSTOM INTERFACE

=head2 Attributes

=head3 files

The internal structure (hash) holding the files. It cannot be set via the
constructor. It's not recommended to modify it by hand.

