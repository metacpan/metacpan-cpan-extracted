package Net::RRP::Protocol;

use strict;
$Net::RRP::Protocol::VERSION = (split " ", '# 	$Id: Protocol.pm,v 1.9 2000/10/12 12:06:50 mkul Exp $	')[3];

=head1 NAME

Net::RRP::Protocol - rrp protocol

=head1 SYNOPSIS

 use Net::RRP::Protocol;
 my $protocol = new Net::RRP::Protocol ( %parameters_for_IO_Socket_SSL_new );
 my $protocol1 = new Net::RRP::Protocol ( socket => $io_socket_ssl_object );

=head1 DESCRIPTION

This class implements rrp command ( request/response ) communications over
socket ( IO::Socket::SSL )

=cut

#use IO::Socket::SSL;
use IO::Socket::INET;
use Net::RRP::Codec;
use Net::RRP::Toolkit;
use Net::RRP::Exception::ServerError;
use Net::RRP::Exception::IOError;

=head2 new

This is a comstructor. You must setup complete paraters for initiliaze of IO::Socket::SSL 
instance or pass already initilized socket at 'socket' key.

 use Net::RRP::Protocol;
 my $protocol = new Net::RRP::Protocol ( %parameters_for_IO_Socket_SSL_new );
 my $protocol1 = new Net::RRP::Protocol ( socket => $io_socket_ssl_object );

See L<IO::Socket::SSL(3)> for more details about IO::Socket::SSL parameters.

=cut

sub new
{
    my ( $class, %options ) = @_;
    my $this = bless{}, $class;
    $this->{socket} = $options{socket} || new IO::Socket::INET ( %options );
    $this->{socket} || die "can't get socket: $!\n";
    $this->{codec} = new Net::RRP::Codec();
    $this;
}

sub _getLinesFromSocket
{
    my $this = shift;

    my $socket = $this->{socket};
    my $buffer = ( $this->{_lineBuffer} ||= '' );
    my $signarute = Net::RRP::Codec::CRLF . '\.' . Net::RRP::Codec::CRLF;
    my $line;

    my $length;

    while ( $length = Net::RRP::Toolkit::safeCall ( sub { $socket->sysread ( $line, 64 ) } ) )
    {
	$buffer .= $line;
	if ( $buffer =~ m/$signarute/s )
	{
	    $this->{_lineBuffer} = $';
	    $buffer = $` . Net::RRP::Codec::CRLF . '.' . Net::RRP::Codec::CRLF;
	    last;
	} else {
	    $this->{_lineBuffer} = $buffer;
        }
    }

    throw Net::RRP::Exception::IOError unless $length;

    $buffer;
}

=head2 getRequest

Get Net::RRP::Request class instance from socket. See L<Net::RRP::Codec(3)> for
more details about parsing of stream && get Net::RRP::Request instance.

 my $request = $protocol->getRequest ();

=cut

sub getRequest
{
    my $this = shift;
    $this->{codec}->decodeRequest ( $this->_getLinesFromSocket() );
}

=head2 getResponse

Get Net::RRP::Response class instance from socket. See L<Net::RRP::Codec(3)> for
more details about parsing of stream && get Net::RRP::Response instance.

 my $response = $protocol->getResponse ();

=cut

sub getResponse
{
    my $this = shift;
    $this->{codec}->decodeResponse ( $this->_getLinesFromSocket() );
}

=head2 sendRequest

Send rrp request to socket. Example:

 $protocol->sendRequest ( $request );

throw throw Net::RRP::Exception::IOError if io errors.

=cut

sub sendRequest
{
    my ( $this, $request ) = @_;
    Net::RRP::Toolkit::safeWrite ( $this->{socket}, $this->{codec}->encodeRequest ( $request ) ) ||
	throw Net::RRP::Exception::IOError ();
}

=head2 sendResponse

Send rrp response to socket. Example:

 $protocol->sendResponse ( $response );

throw throw Net::RRP::Exception::IOError if io errors.

=cut

sub sendResponse
{
    my ( $this, $response ) = @_;
    Net::RRP::Toolkit::safeWrite ( $this->{socket}, $this->{codec}->encodeResponse ( $response ) ) ||
	throw Net::RRP::Exception::IOError();
}

=head2 sendHello()

Send a "hello" message to a socket at the server part. You can pass registryName, version and buildDate parameters to this call.

 $protocol->hello ( registryName => "RU",
		    version      => '1.1.0',
		    buildDate    => 'Mon Jun 19 14:04:00 MSK 2000' ).

Return true if ok and false at errors.

=cut

sub sendHello
{
    my ( $this, %params ) = @_;
    my $registryName = $params{registryName} || $this->{registryName};
    my $buildDate    = $params{buildDate}    || $this->{buildDate};
    my $version      = $params{version}      || $this->{version};
    my $crlf         = Net::RRP::Codec::CRLF;
    my $buffer       = "$registryName RRP Server version $version" . $crlf . "$buildDate" . $crlf . '.' . $crlf;

    Net::RRP::Toolkit::safeWrite ( $this->{socket}, $buffer ) || return throw Net::RRP::Exception::IOError;

    1;
}

=head2 getHello

Get "hello" from scream

 $protocol->getHello();

=cut

sub getHello
{
    my $this = shift;
    my $buffer = $this->_getLinesFromSocket();
    $buffer;
}

1;

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Protocol (C) Michael Kulakov, Zenon N.S.P. 2000
                        125124, 19, 1-st Jamskogo polja st,
                        Moscow, Russian Federation

                        mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::RRP::Request(3)>, L<Net::RRP::Response(3)>, L<Net::RRP::Codec(3)>, RFC 2832

=cut

__END__


