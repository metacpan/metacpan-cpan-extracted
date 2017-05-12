package Net::HTTPTunnel;

use IO::Socket;
use MIME::Base64 ();
require 5.001;

use vars qw($VERSION);

###################################################################
# Copyright (C) 2000 Riad Wahby <rsw@mit.edu> All rights reserved #
# This program is free software.  You may redistribute it and/or  #
# modify it under the same terms as Perl itself.                  #
###################################################################

$VERSION = '0.51';

=pod

=head1 NAME

Net::HTTPTunnel - Create sockets that are tunnels through an HTTP 1.1 proxy

=head1 SYNOPSIS

This is a module that creates sockets that are tunnels through an HTTP
1.1 proxy that supports the SSL CONNECT method.  For more information
on this method, see B<"Tunneling TCP based protocols through Web proxy
servers"> by Ari Luotonen.

    use Net::HTTPTunnel;

    $ht = Net::HTTPTunnel->new( 'proxy-host' => some.host.com
                                'proxy-port' => 80
                                'remote-host' => other.host.com
                                'remote-port' => 443 );

If successful, $ht will be a socket that acts as if it is connected
directly to remote-host:remote-port because all bits will be routed
untouched through the proxy.

The Net::HTTPTunnel constructor returns undef on an error.

=head1 NOTES

Most proxies limit CONNECT tunnels to those which have either 443 or
563 as the destination port.  If you are experiencing errors and are
trying to connect to a port other than one of those two, it is likely
you are running into such a problem.  The only way around this
(assuming you cannot control the proxy settings) is to set up a
listener on the remote machine that you can then connect to any port
through.

Unfortunately, this tunneling method only works for tcp connections.
There is no equivalent way of doing UDP connections.  However, with a
bit of ingenuity such a scheme can certainly be devised---imagine
again the scenario of a TCP listener on the other end of the tunnel.
One could wrap the UDP packets in TCP, transport them through the
tunnel, and unwrap them at the other end with very little trouble.

More information on the HTTP protocol and tunneling can be found in
the Luotonen paper referenced above, as well as in RFCs 1945 and 2068.

=head1 DESCRIPTION

The only member function in Net::HTTPTunnel not inherited from
IO::Socket::INET is the constructor new().  New takes the following
name-value pairs of arguments:

'remote-host' => 'some.host.com' [required]
   The system to which you want the tunnel to connect.

'remote-port' => 563 [required]
   The port on that system.  See note above about port number selection.

'proxy-host' => 'some.host.com' [required]
   The proxy through which this connection will be made.

'proxy-port' => 80 [required]
   The port on the proxy to which a connection should be made.

'http-ver' => '1.1' [optional; default is 1.0]
   The version of HTTP reported in the CONNECT request.  There is no reason 
to change this unless the proxy requires a different version.

'proxy-user' => 'foo' [optional]
   The username to use for proxy authentication, if required.

'proxy-pass' => 'bar' [optional]
   The password for proxy authentication, if required.

'user-agent' => 'baz' [optional]
   The user-agent string to pass along to the HTTP proxy.  If not specified,
it will not be sent.  If you are worried about being spotted as an abberation
in the server logs, perhaps it is better to set this to something fairly tame
like "Mozilla/4.0".

If the connection is successful, a socket will be returned.  On error,
undef is returned instead.

=head1 EXAMPLES

See SYNOPSIS, above.

=head1 SEE ALSO

RFC 1945 --- "Hypertext Transfer Protocol -- HTTP/1.0"

RFC 2068 --- "Hypertext Transfer Protocol -- HTTP/1.1"

"Tunneling TCP based protocols through Web proxy servers" --- Ari Luotonen.

=head1 AUTHOR

Copyright (C) 2001 Riad Wahby E<lt>B<rsw@mit.edu>E<gt> All rights reserved
This program is free software.  You may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 HISTORY

B<0.1> Initial Release

B<0.2> Fixed two bugs, one which included an additional carriage return
with proxy authorization, and one which prevented the http-ver option from
being recognized.

B<0.3> Fixed the capitalization of the "Proxy-Authorization" header in
case a fascist proxy did case-sensitive header matching.  Also, fixed
some mistakes in which \n\r was sent instead of \r\n.

B<0.4> Fixed a bug that would cause an instance of the module to
assume success on all subsequent connections once it had gotten its
first successful connection.

B<0.5> Changed the success test regexp so that "200 OK" is accepted as a
successful reply from the proxy, since some report this instead of
"200 Connection established".  Thanks to JoNO for pointing out this
discrepancy.

B<0.51> D'oh.  Broken regexp.
 
=cut

sub new
{
    my $whatami = shift @_;

    while ($key = shift @_)
    {
        if ($var = shift @_)
        {
            $args{$key} = $var;
        }
    }
    
    $args{'http-ver'} ||= '1.0';

    return undef unless (defined($args{'remote-host'}) && defined($args{'remote-port'}) && defined($args{'proxy-host'}) && defined($args{'proxy-port'}));

# Make a new instance of HTTPTunnel and bless it.
    $new_tunnel = IO::Socket::INET->new( 'PeerAddr' => $args{'proxy-host'},
                                         'PeerPort' => $args{'proxy-port'},
                                         'Proto' => 'tcp' )
        or return undef;

# the CONNECT method itself
    $connectmsg = 'CONNECT ' . $args{'remote-host'} . ':' . $args{'remote-port'} . ' HTTP/' . $args{'http-ver'} . "\015\012";
    
# if we're not 1.0, presumably we're >1.0, in which case we need to send
# the Host: header.  It doesn't really make sense to use a different version
# unless the proxy requires it for some reason---once the connection is made,
# there's no difference at all
    if ($args{'http-ver'} ne '1.0')
    {
        $connectmsg .= 'Host: ' . $args{'proxy-host'} . ':' . $args{'proxy-port'} . "\015\012";
    }
    
# if we're going to do proxy authentication, we don't even need to wait for the
# 407---just send them the first time
    if ($args{'proxy-user'} && $args{'proxy-pass'})
    {
        $upstr = $args{'proxy-user'} . ':' . $args{'proxy-pass'};
        $passstr = MIME::Base64::encode($upstr, '');

        $connectmsg .= 'Proxy-Authorization: Basic ' . $passstr . "\015\012";
    }

# if they specify a user agent, we can use one---it's not required by HTTP, but
# some facist proxies might require one
    if ($args{'user-agent'})
    {
        $connectmsg .= 'User-agent: ' . $args{'user-agent'} . "\015\012";
    }
    
# the final \r\n to indicate the end of the headers
    $connectmsg .= "\015\012";

# send it on
    print $new_tunnel $connectmsg;

# make sure our previous successes don't get to our head
# thanks to Arsen Tevosian for pointing this out
    undef($success);

# now wait for the response
    while (<$new_tunnel>)
    {
# if we get this, we're successful
# Thanks to JoNO for pointing out that some proxies
# return "200 OK" instead of "200 Connection established"
        if (/ 200 /)
        {
            $success = 1;
        }
# a blank line indicates the end of transmission.  This is in
# case the proxy is sending \r\n (because $ will only eat the \n)
        elsif (/^.$/)
        {
            last;
        }
# same as above, but for proxies that only send \n
# such things shouldn't exist, but better safe than sorry
        elsif (/^$/)
        {
            last;
        }
    }

# if we didn't get connection established, we're screwed
    return undef unless $success;

# otherwise, bless it and give the socket back to the user
    bless $new_tunnel, $whatami;
    return $new_tunnel;
}
