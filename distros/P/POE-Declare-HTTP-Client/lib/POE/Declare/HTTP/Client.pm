package POE::Declare::HTTP::Client;

=pod

=head1 NAME

POE::Declare::HTTP::Client - A simple HTTP client based on POE::Declare

=head1 SYNOPSIS

    # Create the web server
    my $http = POE::Declare::HTTP::Client->new(
        Timeout       => 10,
        MaxRedirect   => 7,
        ResponseEvent => \&on_response,
        ShutdownEvent => \&on_shutdown,
    );
    
    # Control with methods
    $http->start;
    $http->GET('http://google.com');
    $http->stop;

=head1 DESCRIPTION

This module provides a simple HTTP client based on L<POE::Declare>.

The implemenetation is intentionally minimalist, making this module an ideal
choice for creating specialised web clients embedded in larger applications.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Scalar::Util              1.19 ();
use Params::Util              1.00 ();
use HTTP::Status                   ();
use HTTP::Request            5.827 ();
use HTTP::Request::Common          ();
use HTTP::Response           5.830 ();
use POE                      1.293 ();
use POE::Filter::HTTP::Parser 1.06 ();
use POE::Wheel::ReadWrite          ();
use POE::Wheel::SocketFactory      ();

our $VERSION = '0.05';

use POE::Declare 0.53 {
	Timeout       => 'Param',
	MaxRedirect   => 'Param',
	ResponseEvent => 'Message',
	ShutdownEvent => 'Message',
	request       => 'Internal',
	previous      => 'Internal',
	factory       => 'Internal',
	socket        => 'Internal',
	redirects     => 'Internal',
};





######################################################################
# Constructor and Accessors

=pod

=head2 new

    my $server = POE::Declare::HTTP::Client->new(
        ResponseEvent => \&on_response,
        ShutdownEvent => \&on_shutdown,
    );

The C<new> constructor sets up a reusable HTTP client that can be enabled
and disabled repeatedly as needed.

=cut





######################################################################
# Control Methods

=pod

=head2 start

The C<start> method enables the web server. If the server is already running,
this method will shortcut and do nothing.

If called before L<POE> has been started, the web server will start
immediately once L<POE> is running.

=cut

sub start {
	my $self = shift;
	unless ( $self->spawned ) {
		$self->spawn;
	}
	return 1;
}

=pod

=head2 stop

The C<stop> method disables the web server. If the server is not running,
this method will shortcut and do nothing.

=cut

sub stop {
	my $self = shift;
	if ( $self->spawned ) {
		$self->post('shutdown');
	}
	return 1;
}

=pod

=head2 GET

    $client->GET('http://www.cpan.org/');

The C<GET> method fetches a named URL via a HTTP GET request.

=cut

sub GET {
	shift->request(
		HTTP::Request::Common::GET(@_)
	);
}

=pod

=head2 HEAD

    $client->HEAD('http://www.cpan.org/');

The C<HEAD> method fetches headers for a named URL via a HTTP HEAD request.

=cut

sub HEAD {
	shift->request(
		HTTP::Request::Common::HEAD(@_)
	);
}

=pod

=head2 POST

    $client->POST('http://www.cpan.org/');

The C<POST> method fetches a named URL via a HTTP POST request.

=cut

sub POST {
	shift->request(
		HTTP::Request::Common::POST(@_)
	);
}

=pod

=head2 PUT

    $client->PUT(
        'http://127.0.0.1:12345/upload.txt',
        Content => 'This is the file content',
    );

The C<PUT> method uploads content to a named URL via a HTTP PUT request.

=cut

sub PUT {
	shift->request(
		HTTP::Request::Common::PUT(@_)
	);
}

=pod

=head2 DELETE

    $client->DELETE('http://www.cpan.org/');

The C<DELETE> method deletes a resource at a URL via a HTTP DELETE request.

=cut

sub DELETE {
	shift->request(
		HTTP::Request::Common::DELETE(@_)
	);
}

=pod

=head2 request

    $client->request( $HTTP_Request );

The C<request> method triggers an arbitrary HTTP request.

It takes any L<HTTP::Request> object, and will respond with an L<HTTP::Response>
object to the C<ResponseEvent> message handler once it is completed.

=cut

sub request {
	my $self    = shift;
	my $request = shift;
	unless ( Params::Util::_INSTANCE($request, 'HTTP::Request') ) {
		die "Missing or invalid HTTP::Request object";
	}

	# Initialise the redirect count
	$self->{redirects} = $self->MaxRedirect || 0;

	# Save the request object
	if ( $self->{request} ) {
		die "HTTP Client is already processing a request";
	} else {
		$self->{request} = $request;
	}

	# Hand off to the event that starts the request
	$self->post('connect');
}

=pod

=head2 running

The boolean C<running> method returns true if the client is both spawned and
processing a request, or false if not. Note that it does not distinguish
between running and idle, and stopped entirely.

=cut

sub running {
	defined $_[0]->{request};
}





######################################################################
# Event Methods

sub connect : Event {
	my $addr    = $_[ARG0];
	my $request = $_[SELF]->{request} or return;
	my $uri     = $request->uri;
	my $host    = ($uri->can('host') and $uri->host) or return;
	my $port    = ($uri->can('port') and $uri->port) || 80;

	# Start the request timeout
	$_[SELF]->timeout_start;

	# Create the socket factory for the request
	$_[SELF]->{factory} = POE::Wheel::SocketFactory->new(
		RemoteAddress => $host,
		RemotePort    => $port,
		SuccessEvent  => 'connect_success',
		FailureEvent  => 'connect_failure',
	);
}

sub timeout : Timeout(30) {
	return unless $_[SELF]->{request};

	if ( $_[SELF]->{factory} ) {
		# Timeout during connect
		$_[SELF]->{factory} = undef;
		$_[SELF]->call(
			response => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
		);

	} elsif ( $_[SELF]->{socket} ) {
		# Timeout during send, processing or response
		$_[SELF]->{socket} = undef;
		$_[SELF]->call(
			response => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
		);

	} else {
		# Unexpected timeout during active request
		$_[SELF]->call(
			response => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
		);

	}
}

sub connect_failure : Event {
	$_[SELF]->timeout_stop;
	$_[SELF]->{factory} = undef;
	$_[SELF]->post(
		response => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
	);
}

sub connect_success : Event {
	$_[SELF]->{factory} = undef;
	$_[SELF]->{socket}  = POE::Wheel::ReadWrite->new(
		Filter     => POE::Filter::HTTP::Parser->new,
		Handle     => $_[ARG0],
		InputEvent => 'socket_response',
		ErrorEvent => 'socket_error',
	);
	$_[SELF]->{request}->protocol('HTTP/1.0');
	$_[SELF]->{request}->user_agent("POE::Declare::HTTP::Client/$VERSION");
	$_[SELF]->{socket}->put( $_[SELF]->{request} );
}

sub socket_error : Event {
	return unless $_[SELF]->{request};

	# If the HTTP filter has a response in it's buffer that does not have
	# a fixed content length, consider it complete and trigger an event.
	my $response = HTTP::Status::HTTP_INTERNAL_SERVER_ERROR;
	if ( $_[SELF]->{socket} ) {
		my $socket  = $_[SELF]->{socket};
		my $filter  = $socket->get_input_filter;
		my $parser  = $filter->{parser};
		if ( $parser->{no_content_length} ) {
			$response = Params::Util::_INSTANCE(
				$filter->{parser}->object, 'HTTP::Response',
			);
		}
	}

	$_[SELF]->post( socket_response => $response );
}

sub socket_response : Event {
	return unless $_[SELF]->{request};

	$_[SELF]->timeout_stop;
	$_[SELF]->{socket} = undef;
	$_[SELF]->post( response => $_[ARG0] );
}

sub response : Event {
	# Check or create the response
	my $response = $_[ARG0];
	unless ( Params::Util::_INSTANCE($response, 'HTTP::Response') ) {
		$response = HTTP::Response->new( $_[ARG0], $_[ARG1] );
	}

	# Associate the response with the original request
	$response->request( delete $_[SELF]->{request} );
	if ( $_[SELF]->{previous} ) {
		$response->previous( delete $_[SELF]->{previous} );
	}

	# Handle redirects
	if ( $response->is_redirect and $_[SELF]->{redirects}-- ) {
		# Prepare the redirect
		my $request  = $response->request;
		my $location = $response->header('Location');
		my $uri      = do {
			local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
			my $base = $response->base;
			$HTTP::URI_CLASS->new($location, $base)->abs($base);
		};

		# Validate the redirect against the HTTP 1.1 rules
		if (
			$request->method =~ /^(?:GET|HEAD)$/
			and
			$uri->scheme ne 'file'
		) {
			# Prepare the new request
			my $referral = $request->clone;
			$referral->remove_header('Host', 'Cookie');
			$referral->uri($uri);

			# Bind the new request
			$_[SELF]->{request}  = $referral;
			$_[SELF]->{previous} = $response;

			# Initiate the new request
			return $_[SELF]->post('connect');
		}
	}

	# Clean up in preparation for the next request
	delete $_[SELF]->{redirects};

	# No further actions needed, return normally
	$_[SELF]->ResponseEvent( $response );
}

sub shutdown : Event {
	$_[SELF]->finish;
	$_[SELF]->ShutdownEvent;
}





######################################################################
# POE::Declare::Object Methods

sub finish {
	my $self = shift;

	# Clear out our stuff
	$self->{request} = undef;
	$self->{factory} = undef;
	$self->{socket}  = undef;

	# Clear out the normal POE stuff
	$self->SUPER::finish(@_);
}

compile;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare-HTTP-Client>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
