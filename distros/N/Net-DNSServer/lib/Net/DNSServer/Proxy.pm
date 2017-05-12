package Net::DNSServer::Proxy;

# $Id: Proxy.pm,v 1.13 2002/11/13 19:57:24 rob Exp $
# This module simply forwards a request to another name server to do the work.

use strict;
use Exporter;
use vars qw(@ISA $default_response_timeout);
use Net::DNSServer::Base;
use Net::DNS;
use Net::DNS::Packet;
use Net::Bind 0.03;
use Carp qw(croak);
use IO::Socket;

@ISA = qw(Net::DNSServer::Base);

# Default timeout in seconds to wait for
# a response from real_dns_server.
$default_response_timeout = 5;

# Created before calling Net::DNSServer->run()
sub new {
  my $class = shift || __PACKAGE__;
  my $self = shift || {};
  if (! $self -> {real_dns_server} ) {
    # Use the first nameserver in resolv.conf as default
    my $res = Net::Bind::Resolv->new('/etc/resolv.conf');
    ($self -> {real_dns_server}) = $res -> nameservers();
    # XXX - This should probably cycle through all the
    # nameserver entries until one successfully accepts.
  }
  $self -> {real_dns_server} = $1
    if $self -> {real_dns_server} =~ /^([\d\.]+)$/;
  # XXX - It should allow a way to override the port
  #       (like host:5353) instead of forcing to 53
  # Initial "connect" to a remote resolver
  my $that_server = IO::Socket::INET->new
    (PeerAddr     => $self->{real_dns_server},
     PeerPort     => "domain",
     Proto        => "udp");
  unless ( $that_server ) {
    croak "Remote dns server [$self->{real_dns_server}] is down.";
  }
  $self -> {that_server} = $that_server;
  $self -> {patience} ||= $default_response_timeout;
  return bless $self, $class;
}

# Called after all pre methods have finished
# Returns a Net::DNS::Packet object as the answer
#   or undef to pass to the next module to resolve
sub resolve {
  my $self = shift;
  my $dns_packet = $self -> {question};
  my $response_data;
  my $old_alarm = 0;
  my $result_packet = undef;
  $@ = "";
  eval {
    local $SIG{ALRM} = sub {
      die "Got bored!\n";
    };
    $old_alarm = alarm ($self->{patience});
    if (!$self -> {that_server} -> send($dns_packet->data)) {
      die "send: $!\n";
    }
    while (1) {
      if (!$self -> {that_server} -> recv($response_data,4096)) {
        die "recv: $!\n";
      }
      $result_packet = Net::DNS::Packet->new(\$response_data);
      if ($result_packet->header->id == $dns_packet->header->id) {
        last;
      }
      $result_packet = undef;
    }
  };
  alarm ($old_alarm);
  if ($@) {
    if ($@ =~ /bored/i) {
      print STDERR "Warning: real_dns_server [$self->{real_dns_server}] did not respond after [$self->{patience}] seconds.\n";
    } else {
      print STDERR "Warning: Failed to proxy via real_dns_server [$self->{real_dns_server}]: $@";
    }
    return undef;
  }
  return $result_packet;
}

1;
__END__

=head1 NAME

Net::DNSServer::Proxy - Forwards requests to another DNS server

=head1 SYNOPSIS

  #!/usr/bin/perl -w -T
  use strict;
  use Net::DNSServer;
  use Net::DNSServer::Proxy;

  my $resolver = new Net::DNSServer::Proxy {
    # Which remote server to proxy to
    real_dns_server => "12.34.56.78",
    # Seconds to wait for its response
    patience => 2,
  };

    -- or --

  # real_dns_server will default to the first
  # "nameserver" entry in /etc/resolv.conf.
  # patience will will default to
  # $Net:DNSServer::Proxy::default_response_timeout.
  my $resolver = new Net::DNSServer::Proxy;

  run Net::DNSServer {
    priority => [$resolver],
  };

=head1 DESCRIPTION

This resolver does not actually do any
resolving itself.  It simply forwards the
request to another server and responds
with whatever the response is from other
server.

=head2 new

The new() method takes a hash ref of properties.

=head2 real_dns_server (optional)

This value is the IP address of the server to
proxy the requests to.  This server should
have a nameserver accepting connections on
the standard named port (53).
It defaults to the first "nameserver" entry
found in the /etc/resolv.conf file.

=head2 patience (optional)

Number of seconds to wait for a response from
real_dns_server before timing out.  It defaults
to $Net:DNSServer::Proxy::default_response_timeout.

=head1 AUTHOR

Rob Brown, rob@roobik.com

=head1 SEE ALSO

L<Net::Bind::Resolv>,
L<Net::DNSServer::Base>,
resolv.conf(5),
resolver(5)

=head1 COPYRIGHT

Copyright (c) 2002, Rob Brown.  All rights reserved.

Net::DNSServer is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

$Id: Proxy.pm,v 1.13 2002/11/13 19:57:24 rob Exp $

=cut
