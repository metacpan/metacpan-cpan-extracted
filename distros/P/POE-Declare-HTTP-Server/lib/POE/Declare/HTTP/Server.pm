package POE::Declare::HTTP::Server;

=pod

=head1 NAME

POE::Declare::HTTP::Server - A simple HTTP server based on POE::Declare

=head1 SYNOPSIS

    # Create the web server
    my $http = POE::Declare::HTTP::Server->new(
        Hostname => '127.0.0.1',
        Port     => '8010',
        Handler  => sub {
            my $server   = shift;
            my $response = shift;
    
            # The request is not passed to you but is available if needed
            my $request = $response->request;
    
            # Webby content generation stuff here
            $response->code( 200 );
            $response->header( 'Content-Type' => 'text/plain' );
            $response->content( "Hello World!" );
    
            return;
        },
    );
    
    # Control with methods
    $http->start;
    $http->stop;

=head1 DESCRIPTION

This module provides a simple HTTP server based on L<POE::Declare>.

The implemenetation is intentionally minimalist, making this module an ideal
choice for creating specialised web servers embedded in larger applications.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Params::Util         1.00 ();
use HTTP::Request       5.827 ();
use HTTP::Response      5.830 ();
use POE                 1.293 ();
use POE::Filter::HTTPD        ();
use POE::Wheel::ReadWrite     ();
use POE::Wheel::SocketFactory ();

our $VERSION = '0.05';





######################################################################
# Constructor and Accessors

=pod

=head2 new

    my $server = POE::Declare::HTTP::Server->new(
        Hostname      => '127.0.0.1',
        Port          => '8010',
        Handler       => \&content,

        StartupEvent  => \&startup_done,
        StartupError  => \&startup_failed,
        ShutdownEvent => \&shutdown_done,
    );

The C<new> constructor sets up a reusable HTTP server that can be enabled
and disabled repeatedly as needed.

It takes three required parameters parameters. C<Hostname>, C<Port> and
C<Handler>.

The C<Handler> parameter should be a C<CODE> reference that will be passed
the server object and a L<HTTP::Response> object. Your code should
fill the provided response object, which will be sent to the client when the
function ends. If your content will change based on the request, you can obtain
the request from the L<HTTP::Response/"request"> method.

The server supports three messages you can register callbacks for.

The C<StartupEvent> message fires after the server socket has been bound and is
available for clients to make requests, and before any connections have been
made from clients.

The C<StartupError> message fires if the server fails to bind to the port, or
has some other error during the socket setup process.

The C<ShutdownEvent> message fires on the completion of a controlled shutdown.

There is currently no C<ShutdownError> event for unexpected server termination,
as this should not occur. An error of this type may, however, be added later.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( Params::Util::_STRING($self->Hostname) ) {
		die "Missing or invalid Hostname param";
	}
	unless ( Params::Util::_POSINT($self->Port) ) {
		die "Missing or invalid Port param";
	}
	unless ( Params::Util::_CODE($self->Handler) ) {
		die "Missing or invalid Handler param";
	}

	# The listening socket
	$self->{server} = undef;

	# The active session (we only support one at a time at the moment)
	$self->{client} = undef;

	return $self;
}

=pod

=head2 Hostname

The C<Hostname> accessor returns the server to bind to, as originally
provided to the constructor.

=head2 Port

The C<Port> accessor returns the port number to bind to, as originally
provided to the constructor.

=head2 Handler

The C<Handler> accessor returns the C<CODE> reference that requests
will be passed to, as provided to the constructor.

=cut

use POE::Declare 0.50 {
	Hostname      => 'Param',
	Port          => 'Param',
	Handler       => 'Param',

	StartupEvent  => 'Message',
	StartupError  => 'Message',
	ShutdownEvent => 'Message',
	ShutdownError => 'Message',

	server        => 'Internal',
	client        => 'Internal',
};





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
		$self->post('startup');
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





######################################################################
# Event Methods

sub startup : Event {

	# Create the socket factory
	$_[SELF]->{server} = POE::Wheel::SocketFactory->new(
		Reuse        => 1,
		BindPort     => $_[SELF]->Port,
		SuccessEvent => 'connect',
		FailureEvent => 'error',
	);

	# If the server survives long enough for this event to fire,
	# it has been started successfully.
	$_[SELF]->post('started');
}

# Signal the successful startup
sub started : Event {
	# If the FailureEvent fired before us, so abort this event
	$_[SELF]->{server} or return;

	# Failure didn't fire, so we must have bound successfully
	$_[SELF]->StartupEvent;
}

# Clean up and signal failure
sub error : Event {
	$_[SELF]->finish;
	$_[SELF]->StartupError;
}

sub connect : Event {
	# This initial implementation only deals with one request at a time.
	# It has the side effect of allowing the request handler to block for
	# a fairly long period of time without too much of an issue.
	$_[SELF]->{server}->pause_accept;

	# Create the socket
	$_[SELF]->{client} = POE::Wheel::ReadWrite->new(
		Filter       => POE::Filter::HTTPD->new,
		Handle       => $_[ARG0],
		InputEvent   => 'request',
		FlushedEvent => 'disconnect',
		ErrorEvent   => 'disconnect',
	);
}

sub request : Event {

	# Create the default response.
	# We default to a server error so that the appropriate return is used
	# if the Handler fails or somehow does nothing to the response.
	my $response = HTTP::Response->new( 500 );
	$response->request( $_[ARG0] );

	# Pass the response (and the request within it) to the handler.
	# Prevent an exception in the handler crashing the entire server.
	eval {
		$_[SELF]->Handler->( $_[SELF], $response );
	};

	# Send the response back to the client.
	# The just wait for the socket to flush
	$_[SELF]->{client}->put( $response );
}

sub disconnect : Event {
	# Handle stray events arriving after intentional shutdown
	$_[SELF]->{server} or return;

	# Clean up the current request, and open up for the next one
	$_[SELF]->{client} = undef;
	$_[SELF]->{server}->resume_accept;
}

sub shutdown : Event {
	$_[SELF]->finish;
	$_[SELF]->ShutdownEvent;
}





######################################################################
# POE::Declare::Object Methods

sub finish {
	my $self = shift;

	# Clear out the server and any active connection
	$self->{server} = undef;
	$self->{client} = undef;

	# Call parent method to clean out other things
	$self->SUPER::finish(@_);
}

compile;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare-HTTP-Server>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
