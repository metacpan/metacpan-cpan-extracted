# $Id: Lite.pm,v 1.13 2004/04/22 20:55:45 davidb Exp $
#
# Copyright (C) 2003 Verisign, Inc.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA

package Net::BEEP::Lite;

use IO::Socket;

use Net::BEEP::Lite::ServerSession;
use Net::BEEP::Lite::ClientSession;

use Carp;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(beep_listen), qw(beep_connect) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.06';

our $errorstr;
our $debug;
our $trace;

=head1 NAME

Net::BEEP::Lite - Perl framework for BEEP (RFC 3080, 3081).

=head1 SYNOPSIS

  use Net::BEEP::Lite qw(beep_connect);
  use Net::BEEP::Lite::ClientSession;

  my $session = beep_connect(Host => localhost,
                             Port => 10288);

  my $channel_num = $session->start_channel
      (URI => 'http://xml.resources.org/profiles/NULL/ECHO');

  my $resp_msg = $session->send_and_recv_message
                   (Content     => "some content",
                    ContentType => 'text/plain');

  print "received response: ", $resp_msg->content(), "\n";

  ---

  use Net::BEEP::Lite::ServerSession;

  my $profile = Net::BEEP::Lite::BaseProfile->new

  beep_listen( Port     => 12345,
               Address  => 127.0.0.1,
               Profiles => [ $profile ],
               Method   => 'fork' );

=head1 ABSTRACT

Net::BEEP::Lite is a lightweight implementation of a BEEP client/server
framework.  This package is intended for implementing fairly simple
BEEP clients and servers.

=head1 DESCRIPTION

Net::BEEP::Lite is a "lightweight" implementation of a BEEP
client/server framework, born out of a desire to have the ability to
simple BEEP client and server work without attempting to be the last
word on BEEP in Perl.

One thing this package does is intentionally fuse the BEEP Listener
role with the Server role, and the Initiatior role with the Client
role.  That is, it makes no attempt to support the peer-to-peer
capabilities of BEEP.

Also, it has only rudimentary support for multiple channels,
especially on the server side.  In particular, by avoiding the use of
threads (or some other complicated forking scheme) it does not handle
asynchronous channels.  Ultimately, on the server side, messages on
different channels are processed serially.  This eliminates one of the
main purposes of using multiple channels.  In fact, the system
defaults not allowing clients to open more than one channel at a time.

That being said, it is possible to support multiple channels, but this
package is easiest to use when using only one.

=head2 EXPORT

=over 4

=item beep_listen( I<ARGS> )

This is a main entry function for running a BEEP server.  It takes a
named arguement list.  It supports the following arguments, in
addition to the arguments accepted by the
C<Net::BEEP::Lite::ServerSession> constructor.:

=over 4

=item Port

The TCP port on which to listen.

=item Address

The address to bind to, if there is more than one interface.

=item Profiles

This should be an array reference of a list of objects that inherit
from C<Net::BEEP::Lite::BaseProfile> (or at least support the same
methods).  At least one profile MUST be supplied here, or clients will
not be able to start any channels.

=item Method

This is a string describing the multitasking method to use.  Currently
the only supported option is 'fork'.  Future options may be 'prefork'
and 'prepostfork'.

=item Socket

If you wish to use this code but want to setup the socket yourself,
you can pass the socket in using this.  If you do so, the Port and
Address parameters will be ignored.

=item Debug

If true, this will spew forth (some) stuff to STDERR.  It defaults to
false.

=item Trace

If true, this will spew forth even more stuff to STDERR, including the
entire conversation.

=back

In general, this function does not return, forming the main event loop
of the server.

=cut

sub beep_listen {
  my %args = @_;

  my ($port, $addr, $sock);
  my $method = 'fork';

  for (keys %args) {
    my $val = $args{$_};

    /^Port$/i and do {
      $port = $val;
      next;
    };
    /^Address|Addr$/i and do {
      $addr = $val;
      next;
    };
    /^Method$/i and do {
      $method = lc $val;
      next;
    };
    /^Debug$/io and do {
      $debug = $val;
      next;
    };
    /^Trace$/io and do {
      $trace = $val;
      next;
    };
    /^Socket$/io and do {
      $sock = $val;
      next;
    };
  }

  # for now, we have one common listen socket creation.
  if (not $sock) {
    $sock = new IO::Socket::INET(LocalPort => $port,
				 LocalAddr => $addr,
				 Proto     => 'tcp',
				 ReuseAddr => 1,
				 Listen    => 5)
      || die "could not create listener socket on port $port: $!";

    print STDERR "Listening on port $port\n" if $debug;
  }

  if ($method eq "fork") {
    _beep_listen_fork($sock, %args);
  }
  else {
    croak "Method '$method' is not implemented";
  }
}

# Use a simple, straight forking method.
sub _beep_listen_fork {
  my $sock     = shift;
  my %args     = @_;

  # we aren't tracking the children, so just ignore their deaths.
  $SIG{CHLD} = 'IGNORE';

  # we will just modify forked copies of this session.
  $args{NoGreeting} = 1;
  my $session = Net::BEEP::Lite::ServerSession->new(%args);

  while (1) {
    my $client_sock = $sock->accept();
    next if not $client_sock;

    my $pid = fork();

    next if $pid;  # the parent just loops on accept.

    # child code:
    $session->_set_socket($client_sock);

    print STDERR "New session started\n" if $debug;
    $session->send_greeting();

    $session->process_messages();
    print STDERR "session ended.\n" if $debug;
    exit(0);
  }
}

=item beep_connect( I<ARGS> )

This is the main entry point for the client.  It will either return a
C<Net::BEEP::Lite::ClientSession>, already connected to the BEEP peer,
or it will return undef and have set C<Net::BEEP::Lite::errorstr>.

It accepts a named parameter list with the following parameters, in
addition to the parameters accepted by the
C<Net::BEEP::Lite::ClientSession> constructor:

=over 4

=item Host

The host to connect to.

=item Port

The port to connect to.

=back

=cut

sub beep_connect {
  my %args = @_;

  my ($host, $port, $socket);

  for (keys %args) {
    my $val = $args{$_};

    /^Port/io and do {
      $port = $val;
      next;
    };
    /^Host/io and do {
      $host = $val;
      next;
    };
    /^Socket$/io and do {
      $socket = $val;
      next;
    };
  }

  if (! $socket) {
    $socket = new IO::Socket::INET(PeerAddr => $host,
				 PeerPort => $port,
				 Proto    => 'tcp')
      || do {
        $errorstr = "could not connect to $host:$port: $!";
        return undef;
    };

    $args{Socket} = $socket;
  }
  return Net::BEEP::Lite::ClientSession->new(%args);
}

=pod

=back

=head2 DEPENDENCIES

This modules depends on:

=over 4

=item C<XML::LibXML>

Available on CPAN.

=back

=head1 SEE ALSO

=over 4

=item RFC 3080

=item RFC 3081

=item L<XML::LibXML>

=back

=head1 AUTHOR

David Blacka, E<lt>davidb@verisignlabs.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Verisign, Inc.
Copyright 2003 by David Blacka

This software is licensed under the GNU LGPL.  See the file
F<beeplite-license.txt>, included in the distribution for the full
license.

=cut

1;
