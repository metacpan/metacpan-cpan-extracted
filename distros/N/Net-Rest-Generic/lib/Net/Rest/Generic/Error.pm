package Net::Rest::Generic::Error;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Net::Rest::Generic::Error - Error handling for Net::Rest::Generic

=head1 SUBROUTINES/METHODS

=head2 throw()

Used like ->new to give an error object.

=head3 USAGE

	ARGUMENT	DESCRIPTION
	---
	type		Describes the variety of failure occurred. Potential
			values could be 'perl error', or basic http error
			codes such as '404', '500', e.t.c.
			~ Default: 'fail'

	category	Describes what actually failed. Potential values
			could be 'http request', 'http auth', or something
			specific to your application like 'foobar api error'.
			~ Default: 'object' (assumes something is wrong with
			  Net::Rest::Generic unless told otherwise)

	message		Describes the specifics of what actually occurred for
			a user to read.
			~ Default: 'unknown'
	---

=cut

sub throw {
	my $class = shift;
	my %args = ref($_[0]) ? %{$_[0]} : @_;
	$args{type}     = $args{type}     ? $args{type}     : 'fail';
	$args{category} = $args{category} ? $args{category} : 'object';
	$args{message}  = $args{message}  ? $args{message}  : 'unknown';
	my $self  = {
		error_type     => $args{type},
		error_category => $args{category},
		error_message  => $args{message},
	};
	return bless $self, $class;
}

=head2 category()

Helper method to retrieve the category of the current error object.

=cut

sub category {
	return shift->{error_category};
}

=head2 message()

Helper method to retrieve the message of the current error object.

=cut

sub message {
	return shift->{error_message};
}

=head2 type()

Helper method to retrieve the type of the current error object.

=cut

sub type {
	return shift->{error_type};
}

1;
