package Net::HL7::Daemon;

use IO::Socket qw(AF_INET INADDR_ANY inet_ntoa);
use base qw(IO::Socket::INET);
use strict;

=pod

=head1 NAME

Net::HL7::Daemon

=head1 SYNOPSIS

my $d = new Net::HL7::Daemon( LocalPort => 12002, Listen => 5 );

=head1 DESCRIPTION

The Net::HL7::Daemon class provides a Daemon, roughly based on the
well known HTTP::Daemon class. The daemon wraps
L<IO::Socket::INET|IO::Socket::INET> so that incoming connections are
returned as Net::HL7::Daemon::Client objects. Other than that the
Daemon class doesn't do all that much. However, this allows you to use
the Daemon class as a base for more elaborate servers, like preforking
or multi-threaded servers. See the Perl Cookbook for examples on this,
and think Net::HL7::Daemon where you see IO::Socket.

=head1 METHODS

=over 4

=item B<$d = new Net::HL7::Daemon()>

Create a new instance of the Daemon class. Arguments are the same as
for the IO::Socket::INET. Default settings are: Listen = SOMAXCONN,
Proto = tcp, Reuse = 1.

=cut

sub new
{
    my($class, %args) = @_;
    $args{Listen} ||= 10;
    $args{Proto}  ||= 'tcp';
    $args{Reuse}  ||= 1;
    return $class->SUPER::new(%args);
}

=pod

=item B<accept([$pkg])>

This method is the same as I<IO::Socket::accept> but returns an
I<Net::HL7::Daemon::Client> reference.  It returns undef if
you specify a timeout and no connection is made within that time.  In
a scalar context the returned value will be a reference to a object of
the I<Net::HL7::Daemon::Client> class which is another
I<IO::Socket::INET> subclass.  In a list context a two-element array
is returned containing the new I<Net::HL7::Daemon::Client> reference
and the peer address; the list will be empty upon failure.

=cut

sub accept
{
    my $self = shift;
    
    my ($sock, $peer) = $self->SUPER::accept("Net::HL7::Daemon::Client");
    if ($sock) {
        ${*$sock}{'hl7d'} = $self;
        return wantarray ? ($sock, $peer) : $sock;
    } else {
        return;
    }
}

=pod

=item B<getHost()>

Returns the host where this daemon can be reached.

=cut

sub getHost
{
    my $self = shift;
    
    my $addr = $self->sockaddr;
    if (!$addr || $addr eq INADDR_ANY) {
 	require Sys::Hostname;
 	return lc(Sys::Hostname::hostname());
    }
    else {
	return gethostbyaddr($addr, AF_INET) || inet_ntoa($addr);
    }
}

=pod

=item B<getPort()>

Returns the port on which this daemon is listening.

=back

=cut

sub getPort {

    my $self = shift;

    return $self->sockport;
}


package Net::HL7::Daemon::Client;

use IO::Socket;
use IO::Socket::Timeout;
use base qw(IO::Socket::INET);
use Net::HL7::Request;
use Net::HL7::Messages::ACK;
use Net::HL7::Connection;
use strict;


=pod 

=head1 NAME

Net::HL7::Daemon::Client

=head1 DESCRIPTION

The I<Net::HL7::Daemon::Client> is also a I<IO::Socket::INET>
subclass. Instances of this class are returned by the accept() method
of I<Net::HL7::Daemon>.

=head1 METHODS

=over 4

=item B<$d = new Net::HL7::Daemon::Client()>

Create a new instance of the Client class. Arguments are the same as
for the IO::Socket::INET. Normally, you shouldn't do this...

=cut

sub new
{
    my($class, %args) = @_;
    $args{Timeout} ||= 10;

    return $class->SUPER::new(%args);
}

=pod

=item B<getRequest()>

Get the current request on this client. The current request is either
the request that has been read by the getNextRequest() method, or if
that hasn't been called yet, the request read from the socket. The
latter is implemented by calling getNextRequest. If both fail,
C<undef> is returned.
In case of failure, then the I<Net::HL7::Daemon::Client>
object ($c) should be discarded, and you should not call this method
again.  

Potentially, a HL7 client can receive more than one
message. So discard the client only when there's no more requests
pending, or the delivering service might experience timeouts.

=cut

sub getRequest
{
    my $self = shift;

    ${*$self}{'REQ'} && return ${*$self}{'REQ'};

    return $self->getNextRequest();
}

=pod

=item B<getNextRequest()>

Read data from the socket and turn it into an I<Net::HL7::Request>
object which is then returned.  It returns C<undef> if reading of the
request fails.  If it fails, then the I<Net::HL7::Daemon::Client>
object ($c) should be discarded, and you should not call this method
again.  Potentially, a HL7 client can receive more than one
message. So discard the client only when there's no more requests
pending, or the delivering service might experience timeouts.

=cut

sub getNextRequest
{
    my $self = shift;

    IO::Socket::Timeout->enable_timeouts_on($self);

    $self->read_timeout(${*$self}{'io_socket_timeout'});
    $self->write_timeout(${*$self}{'io_socket_timeout'});

    {
        local $/ = $Net::HL7::Connection::MESSAGE_SUFFIX;

        use Errno qw(ETIMEDOUT EWOULDBLOCK);

        # slurrrp
        my $buff = <$self>;
     
        if (!$buff && ( 0+$! == ETIMEDOUT || 0+$! == EWOULDBLOCK )) {
            return undef;
        }

        if (not defined $buff) {
            return undef;
        }
        
        # Remove HL7 pre- and suffix
        #
        $buff =~ s/^$Net::HL7::Connection::MESSAGE_PREFIX//;
        $buff =~ s/$Net::HL7::Connection::MESSAGE_SUFFIX$//;
     
        ${*$self}{'REQ'} = new Net::HL7::Request($buff);
    }
    
    return ${*$self}{'REQ'};
}

=pod

=item B<sendAck($res)>

Write a I<Net::HL7::Messages::ACK> message to the client as a
response, to signal success. You may provide your own
Net::HL7::Response, but it is better to rely on the ACK that is
generated internally.

=cut

sub sendAck {

    my ($self, $res) = @_;

    # If this is true, we didn't get the incoming message yet!
    if (! ${*$self}{'REQ'}) {
        $self->getRequest() || return undef;
    }

    if (! ref $res) {
        $res = new Net::HL7::Messages::ACK(${*$self}{'REQ'});
    }

    print $self $Net::HL7::Connection::MESSAGE_PREFIX . $res->toString() .
        $Net::HL7::Connection::MESSAGE_SUFFIX;
}

=pod

=item B<sendNack($errMsg, $res)>

Write a I<Net::HL7::Messages::ACK> message to the client as a
response, with the Acknowledge Code (MSA(1)) set to CE or AE,
depending on the original request, to signal an error.

=cut

sub sendNack {

    my ($self, $errMsg, $res) = @_;

    # If this is true, we didn't get the incoming message yet!
    if (! ${*$self}{'REQ'}) {
        $self->getRequest() || return undef;
    }
    
    if (! ref $res) {
        $res = new Net::HL7::Messages::ACK(${*$self}{'REQ'});
    }
    
    $res->setAckCode("E", $errMsg);
    
    print $self $Net::HL7::Connection::MESSAGE_PREFIX . $res->toString() .
        $Net::HL7::Connection::MESSAGE_SUFFIX;
}

=pod

=item B<sendResponse($res)>

Write a I<Net::HL7::Reponse> object to the client as a response. This
can hold an arbitrary HL7 message.

=back

=cut

sub sendResponse {

    my ($self, $res) = @_;

    print $self $Net::HL7::Connection::MESSAGE_PREFIX . $res->toString() .
        $Net::HL7::Connection::MESSAGE_SUFFIX;
}

=pod

=head1 SEE ALSO

RFC 2068

L<IO::Socket::INET>

=head1 COPYRIGHT

Copyright 2003, D.A.Dokter

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
