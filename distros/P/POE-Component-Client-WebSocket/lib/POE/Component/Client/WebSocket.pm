package POE::Component::Client::WebSocket;

use 5.006;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.27'; 

use Carp qw(carp croak);
use Errno qw(ETIMEDOUT ECONNRESET);

# Explicit use to import the parameter constants;
use POE::Session;
use POE::Driver::SysRW;
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory; 
use POE::Filter::Stackable;
use POE::Filter::SSL;
use POE::Filter::Stream;

# Other various stuff
use URI::Split qw(uri_split);
use MIME::Base64;
use Data::Dumper;

# Crazy frame stuff
use Protocol::WebSocket::Frame;

# HTTP parsing modules
require HTTP::Request;
require HTTP::Response;

# Global stuff for checks etc.
my $validOpts = {
	types => {
		'continuation'  => 1,
		'text'          => 1,
		'binary'        => 1,
		'ping'          => 1,
		'pong'          => 1,
		'close'         => 1,
	}
};

=head1 NAME

POE::Component::Client::WebSocket - A POE compatible websocket client

=head1 VERSION

Version 0.22

=head1 WARNING: Work in progress! Only uploaded early for testing purposes!

This module appears to work perfectly, however its not really been tested that much and I will be amazed if there are not bugs.

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use warnings;
    use strict;

    use POE qw(Component::Client::WebSocket);

    POE::Session->create(
        inline_states => {
            _start => sub {
                my $ws = POE::Component::Client::WebSocket->new('wss://echo.websocket.org');
                $ws->handler('connected','connected');
                $ws->connect;

                $_[HEAP]->{ws} = $ws;

                $_[KERNEL]->yield("next")
            },
            next   => sub {
                $_[KERNEL]->delay(next => 1);
            },
            websocket_read => sub {
                my ($kernel,$read) = @_[KERNEL,ARG0];

                print "Read: $read\n";
           },
           websocket_disconnected => sub {
                warn "Disconnected";
           },
           connected => sub {
                my $req = $_[ARG0];
           },
           websocket_handshake => sub {
                my $res = $_[ARG0];

                $_[KERNEL]->post( $_[SENDER]->ID, 'send', 1234 );

                $_[HEAP]->{ws}->send(5678);
           },
        },
    );

    POE::Kernel->run();
    exit;


=head1 SUBROUTINES/METHODS

=head2 new

Create a new object, takes 1 argument.. a fully qualified websocket URI.

=cut

sub new {
	my ($class,$uri) = @_;

	my $self = bless {
			alias   => __PACKAGE__,
			session => 0,
	}, $class;

	my ($scheme, $auth, $path, $query, $frag) = uri_split($uri);
	my ($host,$port) = split(/:/,$auth);

	# If we are on WSS we are probably using https, if not probably http
	if (!$port) {
			if (uc($scheme) eq 'WSS')       { $port = 443 }
			else                            { $port = 80 }
	}

   
	my $key = "";
	for (1..16) { $key .= int(rand(9)) }

	$self->{session} = POE::Session->create(
			package_states => [
				$self => {
					_start          =>      '_start',
					_stop           =>      '_stop',
					keep_alive      =>      '_keep_alive',
					connect         =>      '_connect',
					handler         =>      '_handler',
					origin          =>      '_origin',
					send            =>      '_send',
					parent          =>      '_parent',
					socket_birth    =>      '_socket_birth',
					socket_death    =>      '_socket_death',
					socket_input    =>      '_socket_input',
				}
			],
			heap => {
				parent          => POE::Kernel->get_active_session()->ID,
				handlers        => {
					read            =>      'websocket_read',
					connected       =>      'websocket_connected',
					handshake       =>      'websocket_handshake',
					disconnected    =>      'websocket_disconnected',
					error           =>      'websocket_error',
				},
				uri             => {
					scheme          => $scheme,
					auth            => $auth,
					path            => $path,
					query           => $query,
					frag            => $frag,
					host            => $host,
					port            => $port,
				},
				req             => {
					'origin'                =>      'http://'.$host,
					'sec-websocket-key'     =>      encode_base64($key),
				},
				_state          => {
					run             =>      1,
					frame           =>      Protocol::WebSocket::Frame->new,
				},
			
			}
	);

	$self->{id} = $self->{session}->ID;

	return $self;    
}

=head1 Default handlers and arguments

All of these can be changed with the 'handler' function, note the 'event key'.

=head2 read (websocket_read)

event key: read
default handler: websocket_read

Data that has been read and decoded from the server.


=head2 disconnected (websocket_disconnected)

event key: disconnected
default handler: websocket_disconnected

Called when the websocket is disconnected.

=head2 connected (websocket_connected)

event key: connected
default handler: websocket_connected

Called when the websocket is connected (before the handshake) ARG0 contains the HTTP::Request sent.

=head2 handshake (websocket_handshake)

event key: handshake
default handler: websocket_handshake

Called when the socket handshake is completed, ARG0 contains the HTTP::Response from the server.

=head2 error (websocket_error)

event key: error
default handler: websocket_error

Called when an error is retrieved, this is a bit vague at the moment ARG0 should contain something.

=head1 OOP mappings from obj to POE

These can be called with a standard POE style POST or directly from the object (see SYNOPSIS for examples of both)

=head2 connect

Start the connection

=cut

sub connect { my $self = shift; POE::Kernel->post( $self->{session}->ID, 'connect', @_ ) }

=head2 handler

Adjust the handlers events are sent to

=cut

sub handler {
        my ($self,$target,$destination) = @_;

        return if ( (!$target) || (!$destination) );

        POE::Kernel->post(
                $self->{session}->ID,
                'handler',
                $target,
                $destination
        );
}

=head2 origin

Change the origin from the automatically generated one to something else.

=cut

sub origin {
        my ($self,$target) = @_;

        return if (!$target);

        POE::Kernel->post(
			$self->{session}->ID,
			'origin',
			$target
        );
}

=head2 parent

Override the 'send to' parent for the module, by default this is the module that the component was started from.

=cut

sub parent {
        my ($self,$target) = @_;

        return if (!$target);

        POE::Kernel->post(
                $self->{session}->ID,
                'parent',
                $target
        );
}

=head2 send

Send data to the server, arguments are:
        1: 'data' the information you want to send.
        2: 'type' the type of information to send (default 'text')
        3: 'fin' wether to send the 'fin' flag (default 1)
        4: 'masked' wether the frame should be masked (default 0)

=cut

sub send {
        my ($self,$data,$type,$fin,$masked) = @_;

        return if (!$data);

        POE::Kernel->post(
                $self->{session}->ID,
                'send',
                $data,$type,$fin,$masked
        );
}


=head1 Internal functions (do not call these directly)

=head2 _start

Initial start handler

=cut

sub _start {
        my ($kernel,$heap) = @_[KERNEL,HEAP];

        $kernel->yield('keep_alive');
}

=head2 _stop

Default stop handler for tidying things up

=cut

sub _stop {
}

=head2 _keep_alive

Do not allow the module to stop running

=cut

sub _keep_alive {
        my ($kernel,$heap) = @_[KERNEL,HEAP];

        return if (!$heap->{_state}->{run});

        $kernel->delay_add('keep_alive' => 1);
}

=head2 _connect

Initate a connect to the websocket

=cut

sub _connect {
        my ($kernel,$heap) = @_[KERNEL,HEAP];

        $heap->{socket} = POE::Wheel::SocketFactory->new(
                RemoteAddress   => $heap->{uri}->{host},
                RemotePort      => $heap->{uri}->{port},
                SuccessEvent    => 'socket_birth',
                FailureEvent    => 'socket_death',
        );}

=head2 _handler

Adjust the distribution map for handlers

=cut

sub _handler {
        my ($kernel,$heap,$target,$destination) = @_[KERNEL,HEAP,ARG0,ARG1];

        $heap->{handlers}->{lc($target)} = $destination;
}

=head2 _origin

Change the origin used in the opening handshake

=cut

sub _origin {
        my ($kernel,$heap,$target) = @_[KERNEL,HEAP,ARG0];

        $heap->{req}->{origin} = $target;
}

=head2 _parent

Change the currently targeted session to communicate events with.

=cut

sub _parent {
        my ($kernel,$heap,$target) = @_[KERNEL,HEAP,ARG0];

        $heap->{parent} = $target;
}

=head2 _send

Send a frame encoded request to the server

=cut

sub _send {
        my ($kernel,$heap,$data,$type,$fin,$masked) = @_[KERNEL,HEAP,ARG0,ARG1,ARG2,ARG3];

        $data = "" if (!$data);
        $type = 'text' if ( (!$type) || (! $validOpts->{types}->{$type}) );
        $fin = 1 if ((!defined $fin) || ($fin !~ m#^[01]$#));
        $masked = 1 if ((!defined $masked) || ($fin !~ m#^[01]$#));

        my $frame = Protocol::WebSocket::Frame->new( buffer => $data, type => $type, fin => $fin, masked => $masked );
        $heap->{wheel}->put($frame->to_bytes);
}

=head2 _socket_birth

Handle a socket when it connects to something

=cut 

sub _socket_birth { 
        my ($kernel, $socket, $sockid, $heap) = @_[KERNEL, ARG0, ARG3, HEAP];

        if ( uc($heap->{uri}->{scheme}) eq 'WSS' ) {
                $heap->{_state}->{sslfilter} = POE::Filter::SSL->new(client=>1);

                $heap->{filters}->{output} = POE::Filter::Stackable->new(Filters => [ $heap->{_state}->{sslfilter} ]);
                $heap->{filters}->{input} = POE::Filter::Stackable->new(Filters => [ $heap->{_state}->{sslfilter} ]);
        } else {
                $heap->{filters}->{output} = POE::Filter::Stackable->new(Filters => []);
                $heap->{filters}->{input} = POE::Filter::Stackable->new(Filters => []);
        }
                
        $heap->{filters}->{output}->push(POE::Filter::Stream->new());
        $heap->{filters}->{input}->push(POE::Filter::Stream->new());

        $heap->{wheel} = POE::Wheel::ReadWrite->new(
			Handle          => $socket,
			Driver          => POE::Driver::SysRW->new(),
			OutputFilter    => $heap->{filters}->{output},
			InputFilter     => $heap->{filters}->{input},
			InputEvent      => 'socket_input',
			ErrorEvent      => 'socket_death',
        );

        my $request = HTTP::Request->new(GET => '/');
        $request->protocol('HTTP/1.1');
        $request->header(
			Upgrade                         => 'WebSocket',
			Connection                      => 'Upgrade',
			Host                            => $heap->{uri}->{host},
			Origin                          => $heap->{req}->{origin},
			'Sec-WebSocket-Key'             => $heap->{req}->{'sec-websocket-key'},
			'Sec-WebSocket-Protocol'        => 'chat',
			'Sec-WebSocket-Version'         => 13,
        );
		
		# Add a lock for when to stop reading the stream
		$heap->{httpresp} = 1;

		# Send the request to the server
        $heap->{wheel}->put($request->as_string());

        # Incase we want to investigate what we sent later.
        $heap->{_state}->{req} = $request;

		# Post back a copy of the request
        $kernel->post( $heap->{parent}, $heap->{handlers}->{'connected'}, $request );
}

=head2 _socket_death

Handle a socket when it is disconnected

=cut

sub _socket_death { 
	my ($kernel,$heap) = @_[KERNEL,HEAP];
	
	$kernel->post( $heap->{parent}, $heap->{handlers}->{disconnected} )	
}

=head2 _socket_input

Read data from the socket

=cut

sub _socket_input { 
        my ($kernel,$heap,$buf) = @_[KERNEL,HEAP,ARG0];

		if ( $heap->{httpresp} ) {
			$heap->{httpbuf} .= $buf;
			
			if ( $heap->{httpbuf} =~ m#\r\n$#m ) {
				# Remove the lock
				delete $heap->{httpresp};
			
                # Keep a copy of the response we got incase we want to have a look at it later
                $heap->{_state}->{res} = $buf;
				
				# Create an investigatable response object
				my $resp = HTTP::Response->parse($heap->{httpbuf});

                # Lets see if we can proceed
                if ($resp->code() == 101) {
                    # Ok connected

					# Send a copy of the handshake back to the users space
					$kernel->post( $heap->{parent}, $heap->{handlers}->{'handshake'}, $resp );
                }
			}

			return;
		}

		$heap->{_state}->{frame}->append($buf);

		while (my $frame = $heap->{_state}->{frame}->next) { $kernel->post( $heap->{parent}, $heap->{handlers}->{read}, $frame ) }
}
 
=head1 AUTHOR

Paul G Webster, C<< <daemon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-client-websocket at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-Client-WebSocket>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::Client::WebSocket


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Client-WebSocket>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Client-WebSocket>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Client-WebSocket>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Client-WebSocket/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Paul G Webster.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of POE::Component::Client::WebSocket
