#! /usr/bin/perl
#
#
# $Id: Proxy.pm 75 2009-08-12 22:08:28Z lem $

package Net::Radius::Server::Set::Proxy;

use 5.008;
use strict;
use warnings;

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 75 $ =~ /\d+/g)[0]/1000 };

use IO::Select;
use IO::Socket::INET;
use Net::Radius::Packet 1.51;
use Net::Radius::Dictionary;
use Net::Radius::Server::Base qw/:set/;
use base qw/Net::Radius::Server::Set/;
__PACKAGE__->mk_accessors(qw/
			  server port secret dictionary result 
			  timeout tries
			  /);

sub _proxy
{
    my $self	= shift;
    my $r_data	= shift;
    my $secret	= shift;
    my $dict	= shift;

    my $req	= $r_data->{request};
    my $pass	= $req->password($r_data->{secret});

    # Construct a packet for our server, passing all the attributes
    # from the original packet - Note that the dict may be different
    # XXX - It may be more efficient to take the chance and use
    # ->{request} instead of re-decoding the packet
    my $p = new Net::Radius::Packet $dict, $r_data->{packet};

    # Send password protected with our shared secret
    $p->set_password($pass, $secret) if $p->attr('User-Password');

    my $packet	= undef;
    my $tries	= 0;
    my $reply	= undef;

    # Format packet properly according to type
    if ($req->code =~ m/Accounting-Request/)
    {
	$p->set_authenticator("\x0" x 16);
	$packet = auth_resp($p->pack, $secret);
    }
    else
    {
	$packet = $p->pack();
    }

    # Attempt to send the request to the real RADIUS server
    while ($tries < $self->tries)
    {
	if ($self->{_socket}->send($packet))
	{
	    if ($self->{_select}->can_read($self->timeout))
	    {
		last if $self->{_socket}->recv($reply, 1024);
		$self->log(2, "[$tries] Failed to recv(): $!");
	    }
	    else
	    {
		$self->log(2, "[$tries] Timeout waiting for server response");
	    }
	}
	else
	{
	    $self->log(1, "[$tries] Send failed: $!");
	}
	$tries ++;
    }

    # No reply - Simply drop this packet and wait
    unless (defined $reply and length($reply) > 0)
    {
	$self->log(2, "Server reply is undef or empty");
	return;
    }

    # Compose reply to the client depending on the packet type
    $r_data->{response} = new Net::Radius::Packet $dict, $reply;

    unless ($r_data->{response})
    {
	$self->log(2, "Failed to parse response packet from server");
	return;
    }

    # Adjust authenticators according to the response type
    my $res = $r_data->{response};
    if ($res->code =~ m/
	Access-Accept
	|Access-Reject
	|Access-Challenge
	|Accounting-Response/x)
    {
	$res->set_authenticator($req->authenticator);
    }
    elsif ($res->code =~ m/Accounting-Request/)
    {
	$res->set_authenticator("\x0" x 16);
    }
    
    # Copy response packet back to our client
    $self->log(4, "Copying packet to my response");
    return 1;
}

sub _set
{
    my $self = shift;
    my $r = $self->set_server(@_);
    unless ($r)
    {
	$self->log(3, "Failure: Return CONTINUE by default");
	return NRS_SET_CONTINUE;
    }

    if ($self->can('result'))
    {
	my $r = $self->result;
	$self->log(4, "Return $r as given result");
	return $r;
    }
    else
    {
	$self->log(4, "Return CONTINUE | RESPOND  as given result");
	return NRS_SET_CONTINUE | NRS_SET_RESPOND;
    }
}

sub set_server
{
    my $self = shift;
    my $r_data = shift;

    $self->timeout(3) unless $self->timeout;
    $self->tries(2) unless $self->tries;
    
    my $secret = $self->secret || $r_data->{secret};
    my $port = $self->port || $r_data->{port};
    my $dict = defined $self->dictionary 
	? Net::Radius::Dictionary->new($self->dictionary) 
	: $r_data->{dict};

    $self->log(4, "Creating udp socket to " . $self->server . ":$port");
    $self->{_socket} = IO::Socket::INET->new
	(
	 PeerAddr	=> $self->server,
	 PeerPort	=> $port,
	 Proto		=> 'udp',
	 );

    unless ($self->{_socket})
    {
	$self->log(2, "Failed to create socket: $!");
	return;
    }

    $self->{_select} = new IO::Select $self->{_socket};
    unless ($self->{_select})
    {
	$self->log(2, "Failed to select object: $!");
	return;
    }
    
    $self->log(4, "Proxying request to " 
	       . $self->server . ":$port");
    $self->_proxy($r_data, $secret, $dict);
}

42;

__END__

=head1 NAME

Net::Radius::Server::Set::Server - Proxy the RADIUS request to a RADIUS server

=head1 SYNOPSIS

  use Net::Radius::Server::Set::Proxy;
  use Net::Radius::Server::Base qw/:set/;


  my $proxy = Net::Radius::Server::Set::Proxy->new
    ({
       server => $real_server_ip,
       port => $real_server_port,
       dictionary => $dictionary_file,
       tries => 2,
       timeout => 3,
       result => NRS_SET_RESPOND,
      });
  my $proxy_sub = $proxy->mk;

=head1 DESCRIPTION

C<Net::Radius::Server::Set::Proxy> allows for proxying the (matching)
RADIUS requests through a RADIUS server. The following attributes are
supported:

=over

=item B<server>

This entry is mandatory and specifies the address of the server to
which the RADIUS request must be sent.

=item B<port>

The port in the RADIUS server where the current request must be
sent. Defaults to the current port.

=item B<secret>

The RADIUS shared secret to be used to protect the interaction with
the server. Defaults to the secret used to handle the current request.

=item B<dictionary>

Dictionary to use for packet coding/decoding when talking to the
RADIUS server. If left unspecified, the currently configured
dictionary will be used to handle that interaction as well.

=item B<timeout>

How many seconds before retrying request to the real RADIUS
server. Defaults to 3 seconds.

=item B<tries>

How many attempts to proxy the request to the real RADIUS
server. Defaults to 2 attempts.

=item B<result>

The result to be returned by the method. See Net::Server::Base(3) for
more information.

=back

When proxying is succesful, C<$self-E<gt>result> will be returned (if
specified). Otherwise, C<NRS_SET_CONTINUE | NRS_SET_RESPOND> will be
returned by default.

Upon a failure in the proxying, C<NRS_SET_CONTINUE> is returned.

=head2 EXPORT

None by default.


=head1 HISTORY

  $Log$
  Revision 1.13  2007/01/03 00:29:58  lem
  Improve check for non-responses

  Revision 1.12  2006/12/14 16:33:17  lem
  Rules and methods will only report failures in log level 3 and
  above. Level 4 report success and failure, for deeper debugging

  Revision 1.11  2006/12/14 15:52:25  lem
  Fix CVS tags


=head1 SEE ALSO

Perl(1), Net::Radius::Server(3), Net::Radius::Server::Radius(3),
Net::Radius::Packet(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut


