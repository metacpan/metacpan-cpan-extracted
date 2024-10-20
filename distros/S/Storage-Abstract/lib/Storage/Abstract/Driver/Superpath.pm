package Storage::Abstract::Driver::Superpath;
$Storage::Abstract::Driver::Superpath::VERSION = '0.006';
use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

# need this in BEGIN block because we use constants from this package
BEGIN { extends 'Storage::Abstract::Driver' }

has param 'superpath' => (
	isa => SimpleStr,
	writer => -hidden,
);

with 'Storage::Abstract::Role::Metadriver';

sub BUILD
{
	my ($self) = @_;

	$self->_set_superpath($self->SUPER::resolve_path($self->superpath));
}

sub source_is_array
{
	return !!0;
}

sub _adjust_path
{
	my ($self, $name) = @_;

	my $superpath = quotemeta($self->superpath . Storage::Abstract::Driver::DIRSEP_STR);
	if ($name =~ s{^$superpath}{}) {
		return $name;
	}

	return undef;
}

sub store_impl
{
	my ($self, $path, $handle) = @_;
	my $new_path = $self->_adjust_path($path);

	Storage::Abstract::X::Readonly->raise(
		"file $path cannot be stored because it's outside of path " . $self->superpath
	) unless defined $new_path;

	return $self->source->store($new_path, $handle);
}

sub is_stored_impl
{
	my ($self, $path) = @_;
	$path = $self->_adjust_path($path);

	return !!0 unless defined $path;
	return $self->source->is_stored($path);
}

sub retrieve_impl
{
	my ($self, $path, $properties) = @_;
	my $new_path = $self->_adjust_path($path);

	Storage::Abstract::X::NotFound->raise("file $path was not found")
		unless defined $new_path;

	return $self->source->retrieve($new_path, $properties);
}

sub dispose_impl
{
	my ($self, $path) = @_;
	my $new_path = $self->_adjust_path($path);

	Storage::Abstract::X::NotFound->raise("file $path was not found")
		unless defined $new_path;

	return $self->source->dispose($new_path);
}

sub list_impl
{
	my $self = shift;
	my $list_aref = $self->source->list(@_);
	my $superpath = $self->superpath . Storage::Abstract::Driver::DIRSEP_STR;

	@{$list_aref} = map { $superpath . $_ } @{$list_aref};
	return $list_aref;
}

1;

__END__

=head1 NAME

Storage::Abstract::Driver::Superpath - Mount under directory metadriver

=head1 SYNOPSIS

	# public file storage
	my $public_storage = Storage::Abstract->new(
		driver => 'directory',
		directory => '/some/directory',
	);

	# make public files visible under /public
	my $storage = Storage::Abstract->new(
		driver => 'superpath',
		source => $public_storage,
		superpath => 'public',
	);

	# these calls will return the same file
	my $fh1 = $public_storage->retrieve('/file');
	my $fh2 = $storage->retrieve('/public/file');

=head1 DESCRIPTION

This metadriver does the opposite of L<Storage::Abstract::Driver::Subpath> - it
mounts its source driver under a passed L</superpath> directory. It will work
as if the entire filesystem was moved to that directory. Any file path must
have L</superpath> prepended to it explicitly in order to successfully target a
file.

=head1 CUSTOM INTERFACE

=head2 Attributes

=head3 source

B<Required> - A L<Storage::Abstract> instance. It can be coerced from a hash
reference, which will be used to call L<Storage::Abstract/new>.

=head3 superpath

B<Required> - A path prefix which will be added to all files in the L</source>
driver.

=head1 CAVEATS

This driver does not allow any file operation outside of L</superpath>. For
most operations it just means it will act as if the file was not present, but
for C<store> it will throw a C<Storage::Abstract::X::Readonly> instead (even
though the storage may not report being readonly). For this reason, it works
best when underlying storage is marked as C<readonly>.

