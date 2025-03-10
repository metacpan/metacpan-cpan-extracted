package Storage::Abstract::Driver::Null;
$Storage::Abstract::Driver::Null::VERSION = '0.007';
use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

extends 'Storage::Abstract::Driver';

with 'Storage::Abstract::Role::Driver::Basic';

sub store_impl
{
	# don't store anywhere
}

sub is_stored_impl
{
	# never true
	return !!0;
}

sub retrieve_impl
{
	# will never be called
}

sub dispose_impl
{
	# will never be called
}

sub list_impl
{
	return [];
}

1;

__END__

=head1 NAME

Storage::Abstract::Driver::Null - Driver which does nothing

=head1 SYNOPSIS

	my $storage = Storage::Abstract->new(
		driver => 'null',
	);

=head1 DESCRIPTION

This driver does nothing. It will silently skip storing any files, and will
never return C<is_stored> as true for any path.

