#!/usr/bin/perl

package POE::Filter::JSON::Incr::Error;
use Any::Moose;

has error => (
	is => "ro",
);

has chunk => (
	is => "ro",
);

__PACKAGE__

__END__

=pod

=head1 NAME

POE::Filter::JSON::Incr::Error - Input error marker

=head1 SYNOPSIS

	# enable the creation of error objects
	POE::Filter::JSON::Incr->new(
		errors => 1,
	);

	# and in your event handler, check for them:
	if ( blessed($_[ARG0]) and $_[ARG0]->isa("POE::Filter::JSON::Incr::Error") ) {
		warn "input error: " . $_[ARG0]->error;
	} else {
		# $_[ARG0] is JSON data
	}

=head1 DESCRIPTION

This is just a simple container for errors and the chunk of text that created
the error.

=head1 ATTRIBUTES

=over 4

=item error

The value of C<$@>, what L<JSON> died with.

=item chunk

The chunk of text that caused the error

=back

=cut


