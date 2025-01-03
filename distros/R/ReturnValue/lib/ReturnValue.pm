package ReturnValue;
use strict;
use v5.14;

use warnings;
no warnings;

use parent qw(Hash::AsObject);

use Carp;

our $VERSION = '0.904';

=encoding utf8

=head1 NAME

ReturnValue - A structured return value for failure or success

=head1 SYNOPSIS

	use ReturnValue;

	sub do_something {
		...;

		return ReturnValue->error(
			value       => $your_usual_error_value,
			description => 'Some longer description',
			tag         => 'short_value'
			) if $failed;

		return ReturnValue->success(
			value       => $your_usual_return_value,
			description => 'Some longer description',
			tag         => 'short_value'
			) unless $failed;
		}


	my $result = do_something();
	if( $result->is_error ) {
		...; # do error stuff
		}

	my $result = do_something_else();
	for( $result->tag ) {
		when( 'tag1' ) { ... }
		when( 'tag2' ) { ... }

		}

=head1 DESCRIPTION

The C<ReturnValue> class provides a very simple wrapper around a value
so you can tell if it's a success or failure without taking pains to
examine the particular value. Instead of using exceptions, you inspect
the class of the object you get back. Errors and successes flow through
the same path.

This isn't particularly interesting for success values, but can be
helpful with multiple ways to describe an error.

=over 4

=cut

sub _new {
	my $allowed = {
		value       => 'required',
		description => 0,
		tag         => 0,
		};

	my( $class, %hash ) = @_;

	delete $allowed->{$_} for keys %hash;

	# these are the keys that are left over after the
	# last foreach. These are a problem if they are
	# requires
	foreach my $key ( keys %$allowed ) {
		next unless $allowed->{$key};
		carp "required key [$key] is missing";
		return;
		}

	bless \%hash, $class;
	}

=item success

Create a success object

=item error

Create an error object

=cut

sub success {
	my( $self ) = shift;
	$self->success_type->_new( @_ );
	}

sub error {
	my( $self ) = shift;
	$self->error_type->_new( @_ );
	}

=item value

The value that you'd normally return. This class doesn't care what it
is. It can be a number, string, or reference. It's up to your application
to figure out how you want to do that.

=item description

A long description of the return values,

=item tag

A short tag suitable for switching on in a C<given>, or something
similar.

=cut

sub value       { $_[0]->{value} }
sub description { $_[0]->{description} }
sub tag         { $_[0]->{tag} }

=item success_type

Returns the class for success objects

=item error_type

Returns the class for error objects

=cut

sub error_type   { 'ReturnValue::Error' }
sub success_type { 'ReturnValue::Success' }

=item is_success

Returns true is the result represents a success

=item is_error

Returns true is the result represents an error

=cut

package ReturnValue::Success {
	use parent qw(ReturnValue);

	sub is_error   { 0 }
	sub is_success { 1 }
	}

package ReturnValue::Error {
	use parent qw(ReturnValue);

	sub is_error   { 1 }
	sub is_success { 0 }
	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/returnvalue/

=head1 AUTHOR

brian d foy, <briandfoy@pobox.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2013-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
