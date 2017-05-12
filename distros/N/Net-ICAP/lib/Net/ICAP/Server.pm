# Net::ICAP::Server -- ICAP Server Implementation
#
# (c) 2014, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Net/ICAP/Server.pm, 0.04 2017/04/12 15:54:19 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Net::ICAP::Server;

use 5.006;

use strict;
use warnings;
use vars qw($VERSION @ISA @_properties @_methods);

($VERSION) = ( q$Revision: 0.04 $ =~ /(\d+(?:\.(\d+))+)/s );

@ISA = qw(Class::EHierarchy);

use Socket;
use IO::Socket::INET;
use Class::EHierarchy qw(:all);
use Net::ICAP;
use Net::ICAP::Common qw(:all);
use Paranoid::Debug;
use Paranoid::Process qw(:all);

@_properties = (
    [ CEH_RESTR | CEH_SCALAR, '_addr',         '0.0.0.0' ],
    [ CEH_RESTR | CEH_SCALAR, '_port',         ICAP_DEF_PORT ],
    [ CEH_RESTR | CEH_SCALAR, '_time-out',     60 ],
    [ CEH_RESTR | CEH_SCALAR, '_max_requests', 0 ],
    [ CEH_RESTR | CEH_SCALAR, '_max_children', 0 ],
    [ CEH_RESTR | CEH_SCALAR, '_options_ttl',  0 ],
    [ CEH_RESTR | CEH_HASH,   '_services' ],
    [ CEH_RESTR | CEH_CODE,   '_reqmod' ],
    [ CEH_RESTR | CEH_CODE,   '_respmod' ],
    [ CEH_RESTR | CEH_CODE,   '_logger' ],
    );
@_methods = ();

#####################################################################
#
# Net::ICAP::Server code follows
#
#####################################################################

sub _initialize {
    my $obj   = shift;
    my %args  = @_;
    my $rv    = 1;
    my @props = $obj->properties;
    my $a;

    pdebug( 'entering w/%s and %s', ICAPDEBUG1, $obj, scalar keys %args );
    pIn();

    # Set internal state
    foreach $a ( keys %args ) {
        if ( grep { $_ eq "_$a" } @props ) {
            unless (
                $obj->set(
                    "_$a", $a eq 'services'
                    ? %{ $args{$a} }
                    : $args{$a} )
                ) {
                pdebug( 'failed to set %s', ICAPDEBUG1, $a );
                $rv = 0;
                last;
            }
        } else {
            pdebug( 'unknown argument: %s', ICAPDEBUG1, $a );
            $rv = 0;
            last;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub istag ($) {

    # Purpose:  Returns code ref to ISTag generation function
    # Returns:  Code ref
    # Usage:    $code = $obj->istag;

    my $obj = shift;
    return $obj->get('_istag');
}

sub _drain ($$) {

    # Purpose:  Drains input buffer until the connection is silent for 5s
    # Returns:  Boolean
    # Usage:    $rv = $obj->_drain($client);

    my $obj    = shift;
    my $client = shift;
    my $rv     = 1;
    my ( $line, $lastInput );

    pdebug( 'entering w/%s', ICAPDEBUG1, $client );
    pIn();

    if ( defined $client ) {
        $client->blocking(0);
        $lastInput = time;
        while ( time - $lastInput < 5 ) {
            while ( defined( $line = $client->getline ) ) {
                $lastInput = time;
            }
            sleep 0.1;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub _error ($;$) {

    # Purpose:  Writes an error response to client
    # Returns:  Boolean
    # Usage:    $rv = $obj->_error($client);

    my $obj    = shift;
    my $status = shift;
    my $resp;

    pdebug( "entering w/%s", ICAPDEBUG1, $status );
    pIn();

    $status = ICAP_BAD_REQUEST unless defined $status;
    $resp = Net::ICAP::Response->new(
        status  => $status,
        headers => {
            ISTag      => &{ $obj->istag },
            Connection => 'close',
            },
            );

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $resp );

    return $resp;
}

sub _options ($$) {

    # Purpose:  Returns an options response
    # Returns:  Response object
    # Usage:    $resp = _options($req);

    my $obj      = shift;
    my $request  = shift;
    my $response = Net::ICAP::Response->new(
        status  => ICAP_OK,
        headers => {
            ISTag             => &{ $obj->istag },
            'Max-Connections' => $obj->get('_max_children'),
            Allow             => 204,
            },
            );

    $response->header( 'Options-TTL', $obj->get('_options_ttl') )
        if $obj->get('_options_ttl');

    return $response;
}

sub _dispatch ($$$) {

    # Purpose:  Calls the applicable function depending on the method
    # Returns:  Boolean
    # Usage:    $rv = $obj->_dispatch($client, $r);

    my $obj      = shift;
    my $client   = shift;
    my $request  = shift;
    my $reqmod   = $obj->get('_reqmod');
    my $respmod  = $obj->get('_respmod');
    my $logger   = $obj->get('_logger');
    my %services = $obj->get('_services');
    my $rv       = 1;
    my ( $service, $method, $response, $r );

    pdebug( 'entering w/%s, %s', ICAPDEBUG1, $client, $request );
    pIn();

    $service = $request->service;
    if ( exists $services{$service} ) {
        $method = $request->method;
        if ( $method eq ICAP_OPTIONS or $services{$service} eq $method ) {
            if ( $method eq ICAP_REQMOD and defined $reqmod ) {
                $response = &$reqmod( $client, $request );
            } elsif ( $method eq ICAP_RESPMOD and defined $respmod ) {
                $response = &$respmod( $client, $request );
            } elsif ( $method eq ICAP_OPTIONS ) {
                $response = $obj->_options($request);
                $response->header( 'Methods', $services{$service} );
            } else {
                $response = $obj->_error(ICAP_METHOD_NOT_IMPLEMENTED);
                $rv       = 0;
            }
        } else {
            $response = $obj->_error(ICAP_METHOD_NOT_ALLOWED);
            $rv       = 0;
        }
    } else {
        $response = $obj->_error(ICAP_SERVICE_NOT_FOUND);
        $rv       = 0;
    }

    # Add ISTag
    $response->header( 'ISTag', &{ $obj->istag } );

    # Log transaction
    &$logger( $client, $request, $response ) if defined $logger;

    # Send the response to the client
    $r = $response->generate($client);
    $rv &= $r;

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub _process ($$) {

    # Purpose:  Processes ICAP traffic on the connection
    # Returns:  Boolean
    # Usage:    $rv = $obj->_process($client);

    my $obj     = shift;
    my $client  = shift;
    my $rv      = 1;
    my $counter = 0;
    my $max_r   = $obj->get('_max_requests');
    my $logger  = $obj->get('_logger');
    my ( $req, $resp, $c );

    pdebug( 'entering w/%s', ICAPDEBUG1, $client );
    pIn();

    while ( $max_r == 0 or $counter < $max_r ) {
        $req = new Net::ICAP::Request;
        if ( $req->parse($client) ) {

            # Send request to dispatcher
            $c = $req->header('Connection');
            if ( $obj->_dispatch( $client, $req ) ) {
                last if defined $c and $c eq 'close';
                $counter++;
            } else {
                $rv = 0;
                last;
            }
        } else {
            $obj->_drain($client);
            $resp = $obj->_error;
            $resp->generate($client);
            &$logger( $client, $req, $resp ) if defined $logger;
            $rv = 0;
            last;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub run ($) {

    # Purpose:  Opens the socket and runs
    # Returns:  Boolean
    # Usage:    $rv = $obj->run;

    my $obj         = shift;
    my $addr        = $obj->get('_addr');
    my $port        = $obj->get('_port');
    my $maxChildren = $obj->get('_max_children');
    my $queueSize   = $maxChildren * 2;
    my $rv          = 1;
    my ( $socket, $client, $cpid );

    pdebug( 'entering', ICAPDEBUG1 );
    pIn();

    MAXCHILDREN = $maxChildren;
    local $SIG{CHLD} = \&sigchld;

    # Open the socket
    $socket = IO::Socket::INET->new(
        ( $addr eq '0.0.0.0' ? (qw(MultiHomed 1)) : ( 'LocalAddr', $addr ) ),
        LocalPort => $port,
        Listen    => $queueSize,
        Type      => SOCK_STREAM,
        Reuse     => 1,
        );

    if ( defined $socket ) {
        while (1) {
            while ( $client = $socket->accept ) {
                if ( defined( $cpid = pfork() ) ) {
                    unless ($cpid) {
                        $obj->_process($client);
                        $client->close;
                        exit 0;
                    }
                } else {
                    pdebug(
                        'failed to fork child for incoming connection: %s',
                        ICAPDEBUG1, $! );
                    $rv = 0;
                }
            }
        }
    } else {
        $rv = 0;
        pdebug( 'failed to open socket: %s', ICAPDEBUG1, $! );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Net::ICAP::Server - ICAP Server Implementation

=head1 VERSION

$Id: lib/Net/ICAP/Server.pm, 0.04 2017/04/12 15:54:19 acorliss Exp $

=head1 SYNOPSIS

    use Net::ICAP::Server;
    use Net::ICAP::Common qw(:req);

    sub cookie_monster {
        my $client   = shift;
        my $request  = shift;
        my $response = new Net::ICAP::Response;
        my $header   = $request->method eq ICAP_REQMOD ?
            $request->reqhdr : $request->reshdr;

        if ($header =~ /\r\nCookie:/sm) {

            # Unfold all header lines
            $header =~ s/\r\n\s+/ /smg;

            # Cookie Monster eat cookie... <smack>
            $header =~ s/\r\nCookie:[^\r]+//smg;

            # Save changes
            $response->status(ICAP_OK);
            $response->body($request->body);
            $request->method eq ICAP_REQMOD ?
                $response->reqhdr($header) :
                $response->reshdr($header);

        } else {
            $response->status(ICAP_NO_MOD_NEEDED);
        }

        return $response;
    }

    sub my_logger {
        my $client   = shift;
        my $request  = shift;
        my $response = shift;
        my ($line, $header, $url);

        # Assemble the URL from the HTTP header
        $header = $request->method eq ICAP_REQMOD ?
            $request->reqhdr : $request->reshdr;
        $url = join '', reverse 
            ($header =~ /^\S+\s+(\S+).+\r\nHost:\s+(\S+)/sm);

        # Create and print the log line to STDERR
        $line = sprintf( "%s %s %s: %s\n",
            ( scalar localtime ),
            $client->peerhost, $response->status, $url );
        warn $line;
    }

    my $server = Net::ICAP::Server->new(
        addr    => '192.168.0.15',
        port    => 1345,
        max_requests => 50,
        max_children => 50,
        options_ttl  => 3600,
        services     => {
            '/outbound' => ICAP_REQMOD,
            '/inbound'  => ICAP_RESPMOD,
            },
        reqmod  => \&cookie_monster,
        respmod => \&cookie_monster,,
        istag   => \&my_istag_generator,
        logger  => \&my_logger,
        );

    $rv = $server->run;

=head1 DESCRIPTION

This is a very basic and crude implementation of an ICAP server.  It is not 
intended to be the basis of a production server, but to serve as an example of
a server utilizing the L<Net::ICAP> modules.

This is a forking server capable of supporting persistent connections with
optional caps in the number of simultaneous connections and the number of
requests that can be performed per connection.

B<OPTIONS> requests are handled automatically by the daemon, as are basic
error responses for bad requests, services not found, and methods not
implemented.

=head1 SUBROUTINES/METHODS

=head2 new

    my $server = Net::ICAP::Server->new(
        addr    => '192.168.0.15',
        port    => 1345,
        max_requests => 50,
        max_children => 50,
        options_ttl  => 3600,
        services     => {
            '/outbound' => ICAP_REQMOD,
            '/inbound'  => ICAP_RESPMOD,
            },
        reqmod  => \&cookie_monster,
        respmod => \&cookie_monster,,
        istag   => \&my_istag_generator,
        logger  => \&my_logger,
        );

This method creates a new ICAP server.  All of the arguments are technically
optional, but the B<services> hash, B<reqmod> and/or B<respmod> code refs are
the minimum to have a functioning server.

The following chart describes the available options:

    Argument        Default     Description
    ----------------------------------------------------------
    addr          '0.0.0.0'     Address to listen on
    port               1344     Port to listen on
    max_requests          0     Number of requests allowed per 
                                connection (0 == unlimited)
    max_children          0     Number of simultaneous clients 
                                allowed    (0 == unlimited)
    options_ttl           0     Seconds OPTIONS are good for
                                           (0 == forever)
    services             ()     Map of service URIs to method
    reqmod            undef     Callback function for REQMOD
    respmod           undef     Callback function for RESPMOD
    istag      sub { time }     ISTag generation function
    logger            undef     Callback function for logging

B<reqmod> and B<respmod> functions will be called with two arguments, those
being the L<IO::Socket::INET> for the client connection and the
L<Net::ICAP::Request> object.  They should return a valid
L<Net::ICAP::Response> object.

B<logger> will be called with three arguments:  the client socket object, the
request and the response objects.

=head2 istag

    $code = $server->istag;

Just a convenience method for pulling the B<ISTag> generation function's code
reference.  Read only.

=head2 run

    $rv = $server->run;

This method creates the listening socket and begins forking with each
connection made it.

=head1 DEPENDENCIES

=over

=item o L<Paranoid>

=item o L<Class::EHierarchy>

=item o L<IO::Socket::INET>

=back

=head1 BUGS AND LIMITATIONS 

This is not a full or robust implementation.  This is sample code.  Really.
Write something better.

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2014, Arthur Corliss (corliss@digitalmages.com)

