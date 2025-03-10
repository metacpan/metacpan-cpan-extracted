package Storage::Abstract::Driver::Composite;
$Storage::Abstract::Driver::Composite::VERSION = '0.007';
use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

use Scalar::Util qw(blessed);

extends 'Storage::Abstract::Driver';

has field '_cache' => (
	isa => HashRef,
	clearer => 1,
	lazy => sub { {} },
);

with 'Storage::Abstract::Role::Driver::Meta';

sub source_is_array
{
	return !!1;
}

sub refresh
{
	my ($self) = @_;

	$self->_clear_cache;
}

sub _run_on_sources
{
	my ($self, $name, $callback) = @_;
	my $finished = !!0;

	# run on one cached source
	my $cached_source = defined $name ? $self->_cache->{$name} : undef;
	if ($cached_source) {
		$finished = $callback->($cached_source);
	}

	# if there was no cached source or $callback did not return true, do it on
	# all sources
	if (!$finished) {
		foreach my $source (@{$self->source}) {
			if ($finished = $callback->($source)) {
				$self->_cache->{$name} = $source
					if defined $name;
				last;
			}
		}
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

	Storage::Abstract::X::StorageError->raise('could not store')
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

	my $stored = !!0;
	my $retrieved = $self->_run_on_sources(
		$name,
		sub {
			my $source = shift;

			if ($source->is_stored($name)) {
				$stored = !!1;
				return $source->retrieve($name, $properties);
			}

			return undef;
		}
	);

	Storage::Abstract::X::NotFound->raise('file was not found')
		unless $stored;

	Storage::Abstract::X::StorageError->raise('could not retrieve')
		unless defined $retrieved;

	return $retrieved;
}

sub dispose_impl
{
	my ($self, $name) = @_;

	my $stored = !!0;
	my $disposed = $self->_run_on_sources(
		$name,
		sub {
			my $source = shift;

			if ($source->is_stored($name)) {
				$stored = !!1;
				return !!0 if $source->readonly;

				$source->dispose($name);
				return !!1;
			}

			return !!0;
		}
	);

	Storage::Abstract::X::StorageError->raise('file was not found')
		unless $stored;

	Storage::Abstract::X::StorageError->raise('could not dispose')
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

Storage::Abstract::Driver::Composite - Aggregate meta driver

=head1 SYNOPSIS

	my $storage = Storage::Abstract->new(
		driver => 'composite',
		source => [
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

This meta driver can hold a number of drivers under itself (in sequence) and
choose the first driver which holds a given file.

=head2 Choosing the source

This driver will use the following logic to find a source suitable to store /
retrieve a file:

=over

=item

Check the L</source> array in order, starting from index 0.

=item

If the source is readonly, skip it if the operation being performed is
modifying the storage.

=item

If the source doesn't report having this file (as with C<is_stored>), skip it
(unless we are storing).

=item

If the source was not skipped in the previous steps, use it.

=back

After the first successful pairing of a path with a source, it will be cached.
Future operations on this path will prefer to use the cached source, but if
they were to fail, they will fall back to checking all sources once again.

If any source raises an exception, the execution will stop since it will not be
caught. Driver will check if the sources have the files stored explicitly, so
C<NotFound> exception should not be raised unless no sources store that file.

Unless you want to possibly have duplicated files in your sources, you should
mark all but one nested drivers as readonly.

=head1 CUSTOM INTERFACE

=head2 Attributes

=head3 source

B<Required> - An array reference of L<Storage::Abstract> instances. Each
instance can be coerced from a hash reference, which will be used to call
L<Storage::Abstract/new>. Their order is significant - they will be tried in
sequence.

=head1 CAVEATS

This driver does not allow using C<set_readonly> on it - trying to do so will
always result in an exception (unblessed).

This driver caches the readonly state of its subdrivers to avoid rechecking it
on every call. You can call C<refresh> to make it recalculate the readonly state.

