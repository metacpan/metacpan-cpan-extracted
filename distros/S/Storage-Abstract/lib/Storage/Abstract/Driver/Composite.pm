package Storage::Abstract::Driver::Composite;
$Storage::Abstract::Driver::Composite::VERSION = '0.002';
use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

use Feature::Compat::Try;
use Scalar::Util qw(blessed);

extends 'Storage::Abstract::Driver';

has param 'sources' => (
	coerce => ArrayRef [
		(InstanceOf ['Storage::Abstract'])
		->plus_coercions(HashRef, q{ Storage::Abstract->new(%$_) })
	],
);

has field 'errors' => (
	isa => ArrayRef,
	writer => -hidden,
);

has field '_cache' => (
	isa => HashRef,
	clearer => -public,
	lazy => sub { {} },
);

sub _run_on_source
{
	my ($self, $callback, $source, $errors) = @_;
	try {
		return $callback->($source);
	}
	catch ($e) {
		push @$errors, [$source, $e];
		return !!0;
	}
}

sub _run_on_sources
{
	my ($self, $name, $callback) = @_;
	my $finished = !!0;
	my @errors;

	# run on one cached source
	my $cached_source = defined $name ? $self->_cache->{$name} : undef;
	if ($cached_source) {
		$finished = $self->_run_on_source($callback, $cached_source, \@errors);
	}

	# if there was no cached source or $callback did not return true, do it on
	# all sources
	if (!$finished) {
		@errors = ();
		foreach my $source (@{$self->sources}) {
			if ($finished = $self->_run_on_source($callback, $source, \@errors)) {
				$self->_cache->{$name} = $source
					if defined $name;
				last;
			}
		}
	}

	if (@errors) {
		$self->_set_errors(\@errors);
	}

	return $finished;
}

sub store_impl
{
	my ($self, $name, $handle) = @_;

	my $stored = $self->_run_on_sources(
		$name,
		sub {
			my $source = shift;
			return !!0 if $source->readonly;

			$source->store($name, $handle);
			return !!1;
		}
	);

	Storage::Abstract::X::StorageError->raise("None of the sources were able to store $name")
		unless $stored;
}

sub is_stored_impl
{
	my ($self, $name) = @_;

	my $stored = $self->_run_on_sources(
		$name,
		sub {
			my $source = shift;

			return $source->is_stored($name);
		}
	);

	return $stored;
}

sub retrieve_impl
{
	my ($self, $name, $properties) = @_;

	my $retrieved = $self->_run_on_sources(
		$name,
		sub {
			my $source = shift;

			if ($source->is_stored($name)) {
				return $source->retrieve($name, $properties);
			}

			return !!0;
		}
	);

	Storage::Abstract::X::StorageError->raise("Could not retrieve $name")
		unless $retrieved;

	return $retrieved;
}

sub dispose_impl
{
	my ($self, $name) = @_;

	my $disposed = $self->_run_on_sources(
		$name,
		sub {
			my $source = shift;
			return !!0 if $source->readonly;

			if ($source->is_stored($name)) {
				$source->dispose($name);
				return !!1;
			}

			return !!0;
		}
	);

	Storage::Abstract::X::StorageError->raise("Could not dispose $name")
		unless $disposed;
}

sub list_impl
{
	my ($self) = @_;

	my %all_files;
	$self->_run_on_sources(
		undef,
		sub {
			my $source = shift;

			foreach my $filename (@{$source->list}) {
				$all_files{$filename} = 1;
			}

			return !!0;
		}
	);

	return [keys %all_files];
}

1;

__END__

=head1 NAME

Storage::Abstract::Driver::Composite - Use multiple sources of storage

=head1 SYNOPSIS

	my $storage = Storage::Abstract->new(
		driver => 'composite',
		sources => [
			{
				driver => 'directory',
				directory => '/some/dir',
				readonly => !!1,
			}
			{
				driver => 'memory'
			},
		],
	);

=head1 DESCRIPTION

This driver can hold a number of drivers under itself (in sequence) and choose
the first driver which holds a given file.

=head2 Choosing the source

This driver will use the following logic to find a source suitable to store /
retrieve a file:

=over

=item

Check the L</sources> array in order, starting from index 0.

=item

If the source is readonly, skip it if the operation being performed is
modifying the storage.

=item

If the source doesn't report having this file (as with C<is_stored>), skip it
(unless we are storing).

=item

If the source encounters an exception, write it into L</errors> and skip it.

=item

If the source was not skipped in the previous steps, use it.

=back

After the first successful pairing of a path with a source, it will be cached.
Future operations on this path will prefer to use the cached source, but if
they were to fail, they will fall back to checking all sources once again.

Unless you want to possibly have duplicated files in your sources (due to the
driver falling back to other sources on exceptions), you should mark all but
one nested drivers as readonly.

=head1 CUSTOM INTERFACE

=head2 Attributes

=head3 sources

B<Required> - An array reference of L<Storage::Abstract> instances. Each
instance be coerced from a hash reference, which will be used to call
L<Storage::Abstract/new>. Their order is significant - they will be tried in
sequence.

=head3 errors

This is an array reference which will be populated with source errors if they
occur. Each element in the array will be an array reference of two elements -
the first element will be the source instance from L</sources>, while the
second one will be the exception which was caught.

This structure can be examined to see whether any of the sources encountered
errors when performing their operations. It's probably wise to examine it when
catching C<Storage::Abstract::X::StorageError>.

It cannot be set in the constructor, obviously.

=head2 Methods

=head3 clear_cache

This method will clear the internal cache of the driver.

