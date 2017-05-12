package Nagios::Plugin::OverHTTP::Parser::Standard;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.16';

###########################################################################
# MOOSE
use Moose 0.74;
use MooseX::StrictConstructor 0.08;

###########################################################################
# ROLES
with 'Nagios::Plugin::OverHTTP::Parser';

###########################################################################
# MOOSE TYPES
use Nagios::Plugin::OverHTTP::Library qw(Status);

###########################################################################
# MODULE IMPORTS
use Carp qw(croak);
use Const::Fast qw(const);
use HTML::Strip 1.05;
use HTTP::Status 5.817;
use Nagios::Plugin::OverHTTP::Library 0.14;
use Nagios::Plugin::OverHTTP::Response;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# PRIVATE CONSTANTS
const my $ERROR_BAD_STATUS   => q{Status header %s is in valid};
const my $HEADER_MESSAGE     => 'X-Nagios-Information';
const my $HEADER_PERFORMANCE => 'X-Nagios-Performance';
const my $HEADER_STATUS      => 'X-Nagios-Status';

###########################################################################
# ATTRIBUTES
has 'auto_correct_html' => (
	is  => 'rw',
	isa => 'Bool',
	default => 1,
	documentation => q{Specifies if HTML responses should be stripped of tags},
);
has 'default_status' => (
	is  => 'rw',
	isa => Status,
	coerce => 1,
	default => 'UNKNOWN',
	documentation => q{This is the default status to use if no status is found in the response},
);
has 'parse_headers' => (
	is  => 'rw',
	isa => 'Bool',
	default => 1,
	documentation => q{Specifies if the headers of the response should be parsed},
);

###########################################################################
# METHODS
sub parse {
	my ($self, $response) = @_;

	# Location to collect information
	my %collected_information;

	if ($self->parse_headers) {
		# Parse the headers
		my $header_information = $self->_parse_headers($response);

		# Since nothing was parsed before, just set
		%collected_information = %{$header_information};
	}

	if (!exists $collected_information{message}) {
		if (!$response->is_success) {
			# The response is not a success; status line as first line, then content
			$collected_information{message} = join qq{\n},
				$response->status_line,
				$response->decoded_content;
		}

		if (HTTP::Status::is_server_error($response->code)) {
			# Internal server error, so modify the default status code
			$collected_information{status} = $Nagios::Plugin::OverHTTP::Library::STATUS_CRITICAL;
		}
	}

	if (!exists $collected_information{message}) {
		# No message collected, so parse the body
		my $body_information = $self->_parse_body($response,
			# Specify to scrape status if no status found
			scrape_status => !exists $collected_information{status}
		);

		if (exists $body_information->{message}) {
			# Store the message
			$collected_information{message} = $body_information->{message};
		}

		if (exists $body_information->{status}) {
			# Store the status
			$collected_information{status} = $body_information->{status};
		}

		if (exists $body_information->{performance_data}) {
			# The body contained some performance data
			if (exists $collected_information{performance_data}) {
				# Some performance data already exists, so add it to the end
				$collected_information{performance_data} =
					$body_information->{performance_data} . qq{\n} . $collected_information{performance_data};
			}
			else {
				# Just set it
				$collected_information{performance_data} = $body_information->{performance_data};
			}
		}
	}

	if (!exists $collected_information{message}) {
		# The message still does not exist, so set to status line and response
		$collected_information{message} = join qq{\n},
			$response->status_line,
			$response->as_string;
	}

	if (!exists $collected_information{status}) {
		# The status still does not exist, so set to the default status
		$collected_information{status} = $self->default_status;
	}

	# Return the response object
	return Nagios::Plugin::OverHTTP::Response->new(
		response => $response,
		%collected_information,
	);
}

###########################################################################
# PRIVATE METHODS
sub _parse_body {
	my ($self, $response, %args) = @_;

	# Get the scrape status
	my $scrape_status = exists $args{scrape_status} ? $args{scrape_status}
	                                                : 1 # Default
	                                                ;

	# Make a HASH for the collected information
	my %collected_information;

	# Get the body content
	my $body = $self->auto_correct_html ? $self->_strip_html($response)
	                                    : $response->decoded_content
	                                    ;

	# Split the body content into lines
	my @lines = split m{(?:\r?\n|\n?\r)}msx, $body;

	if (!@lines) {
		# There is no content to parse
		return {};
	}

	# First line is message + optional performance data
	@collected_information{qw(message performance_data)} = shift(@lines)
		=~ m{\A ([^\|]+?) (?:\s* \| \s* (.*))? \z}msx;

	if (!defined $collected_information{performance_data}) {
		# Change to an empty string
		$collected_information{performance_data} = q{};
	}

	# Walk through the rest of the lines
	LINE:
	while (defined(my $line = shift @lines)) {
		if ($line =~ m{\A ([^\|]+?) \s* \| \s* (.*) \z}msx) {
			# This line ends the plugin output and begins the performance data
			$collected_information{message} .= qq{\n$1};
			$collected_information{performance_data} .= qq{\n} . join qq{\n}, $2, @lines;
			last LINE;
		}
		else {
			# This is just a normal line
			$collected_information{message} .= qq{\n$line};
		}
	}

	if ($scrape_status && $collected_information{message} =~
		m{\A (?:[^a-z]+ \s+)? (OK|WARNING|CRITICAL|UNKNOWN)\b}msx) {
		# Scraped the status from the message
		my $status = to_Status($1);

		if (defined $status) {
			# Collect the valid status
			$collected_information{status} = $status;
		}
	}

	if ($collected_information{performance_data} eq q{}) {
		# There was no collected performance data
		delete $collected_information{performance_data};
	}

	# Return the collected information
	return \%collected_information;
}
sub _parse_headers {
	my ($self, $response) = @_;

	# Create a HASH to store information
	my %collected_information;

	if (defined $response->header($HEADER_MESSAGE)) {
		# The message header is present, so this is the message
		$collected_information{message} = join qq{\n},
			$response->header($HEADER_MESSAGE);
	}

	if (defined $response->header($HEADER_PERFORMANCE)) {
		# The performance data header is present
		$collected_information{performance_data} = join qq{\n},
			$response->header($HEADER_PERFORMANCE);
	}

	if (defined $response->header($HEADER_STATUS)) {
		# The status header is present
		my $status_header = $response->header($HEADER_STATUS);

		# Attempt to convert to a proper status value
		my $status = to_Status($status_header);

		if (!defined $status) {
			# The status is not valid, and this is REQUIRED to be valid
			croak sprintf $ERROR_BAD_STATUS, $status_header;
		}

		# Collect the information
		$collected_information{status} = $status;
	}

	# Return all collected information
	return \%collected_information;
}
sub _strip_html {
	my ($self, $response) = @_;

	# Get the response body
	my $body = $response->decoded_content;

	if ($response->headers->content_type ne q{}
		&& !$response->headers->content_is_html) {
		# This response is not elligable for HTML stripping
		return $body;
	}

	# Create the HTML stripper object
	my $html_stripper = HTML::Strip->new(
		decode_entities => 1,
		emit_spaces => 1,
	);

	# Strip the content
	$body = $html_stripper->parse($body);

	# Strip leading/trailing whitespace
	$body =~ s{\A \s+ | \s+ \z}{}gmsx;

	return $body;
}

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Nagios::Plugin::OverHTTP::Parser::Standard - The standard response parser

=head1 VERSION

This documentation refers to L<Nagios::Plugin::OverHTTP::Parser::Standard>
version 0.16

=head1 SYNOPSIS

  #TODO: Write this

=head1 DESCRIPTION

This is the standard parser for L<Nagios::Plugin::OverHTTP>.

=head1 CONSTRUCTOR

This is fully object-oriented, and as such before any method can be used, the
constructor needs to be called to create an object to work with.

=head2 new

This will construct a new plugin object.

=over

=item B<< new(%attributes) >>

C<< %attributes >> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<< new($attributes) >>

C<< $attributes >> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=back

=head1 METHODS

=head2 parse

This takes a L<HTTP::Response> object and parses it and will return a
L<Nagios::Plugin::OverHTTP::Response> object.

=head1 DIAGNOSTICS

=over 4

=item C<< Status header %s is in valid >>

The status header that was provided did not contain any known status format.

=back

=head1 DEPENDENCIES

This module is dependent on the following modules:

=over 4

=item * L<Carp>

=item * L<Const::Fast>

=item * L<HTML::Strip> 1.05

=item * L<HTTP::Status> 5.817

=item * L<Moose> 0.74

=item * L<MooseX::StrictConstructor> 0.08

=item * L<Nagios::Plugin::OverHTTP::Library> 0.14

=item * L<Nagios::Plugin::OverHTTP::Parser>

=item * L<Nagios::Plugin::OverHTTP::Response>

=item * L<namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-nagios-plugin-overhttp at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Plugin-OverHTTP>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Douglas Christopher Wilson, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
