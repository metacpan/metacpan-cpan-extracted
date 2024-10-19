package Storage::Abstract::Driver::Subpath;
$Storage::Abstract::Driver::Subpath::VERSION = '0.005';
use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

# need this in BEGIN block because we use constants from this package
BEGIN { extends 'Storage::Abstract::Driver' }

has param 'subpath' => (
	isa => SimpleStr,
	writer => -hidden,
);

with 'Storage::Abstract::Role::Metadriver';

sub BUILD
{
	my ($self) = @_;

	$self->_set_subpath($self->SUPER::resolve_path($self->subpath));
}

sub source_is_array
{
	return !!0;
}

sub resolve_path
{
	my ($self, $name) = @_;
	$name = $self->SUPER::resolve_path($name);

	# first resolve, then join path. If the order was reversed, leaving new
	# root would be possible.
	return $self->subpath . Storage::Abstract::Driver::DIRSEP_STR . $name;
}

sub store_impl
{
	my $self = shift;
	return $self->source->store(@_);
}

sub is_stored_impl
{
	my $self = shift;
	return $self->source->is_stored(@_);
}

sub retrieve_impl
{
	my $self = shift;
	return $self->source->retrieve(@_);
}

sub dispose_impl
{
	my $self = shift;
	return $self->source->dispose(@_);
}

sub list_impl
{
	my $self = shift;
	my $list_aref = $self->source->list(@_);
	my $subpath = quotemeta($self->subpath . Storage::Abstract::Driver::DIRSEP_STR);

	my @result;
	foreach my $name (@{$list_aref}) {
		next unless $name =~ s{^$subpath}{};
		push @result, $self->SUPER::resolve_path($name);
	}

	return \@result;
}

1;

__END__

=head1 NAME

Storage::Abstract::Driver::Subpath - Change root metadriver

=head1 SYNOPSIS

	# general file storage
	my $storage = Storage::Abstract->new(
		driver => 'directory',
		directory => '/some/directory',
	);

	# subpath of the file storage for public files
	my $public_storage = Storage::Abstract->new(
		driver => 'subpath',
		source => $storage,
		subpath => '/public',
	);

	# these calls will return the same file
	my $fh1 = $storage->retrieve('/public/file');
	my $fh2 = $public_storage->retrieve('/file');

=head1 DESCRIPTION

This metadriver can modify another driver to use a different path than root. It
will work as if the root of the L</source> driver was changed to L</subpath>.

It is impossible (as intended) to get files outside the L</subpath> using this
driver.

=head1 CUSTOM INTERFACE

=head2 Attributes

=head3 source

B<Required> - A L<Storage::Abstract> instance. It can be coerced from a hash
reference, which will be used to call L<Storage::Abstract/new>.

=head3 subpath

B<Required> - A path prefix for all paths passed to the L</source> driver.

