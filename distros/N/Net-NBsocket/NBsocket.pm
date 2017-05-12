#!/usr/bin/perl

package Net::NBsocket;
use strict;
#use diagnostics;

use vars qw(
	$VERSION @ISA @EXPORT_OK $UDP $TCP
);
use POSIX;
use NetAddr::IP::InetBase qw(
	ipv6_aton
	ipv6_n2x
	ipv6_n2d
	inet_pton
	inet_ntop
	AF_INET6
);
use AutoLoader 'AUTOLOAD';
require Socket;
import Socket qw(
	sockaddr_in
	sockaddr_un
	inet_aton
	inet_ntoa
	INADDR_ANY
	INADDR_BROADCAST
	INADDR_LOOPBACK
	INADDR_NONE
	AF_INET
	AF_UNIX
	SOCK_STREAM
	SOCK_DGRAM
	SO_LINGER
	SO_REUSEADDR
	SOL_SOCKET
	SOMAXCONN
);
  
require Exporter;

@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.24 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

# dynamic configuration for this HOST

# used a lot, create once per session
# SEGFAULTS with Apache mod_perl
#$UDP = getprotobyname('udp');
#$TCP = getprotobyname('tcp');

$UDP = 17;
$TCP = 6;

my $havesock6 = 0;
my $isupport6 = 0;
my $in6addr_any = ipv6_aton('::0');
my $in6addr_loopback = ipv6_aton('::1');

if (eval { require Socket6 } ) {	# have Socket6?
  $havesock6 = 1;
  import Socket6 qw(
	pack_sockaddr_in6
	unpack_sockaddr_in6
	in6addr_any
	in6addr_loopback
  );

  my $sock = do { local *SOCK; };

  if (socket($sock,AF_INET6(),SOCK_STREAM(),$TCP)) {
    $isupport6 = 1;
    close $sock;
  }
}
else {
  *pack_sockaddr_in6		= \&_dummy;
  *unpack_sockaddr_in6		= \&_dummy;
  *in6addr_any			= sub { return $in6addr_any };
  *in6addr_loopback		= sub { return $in6addr_loopback};
}

# get the index into sockaddr_in for the AF family byte
#

# return an index of '0' or '1' for the AF family byte
# '2' in the first rv indicates a not found
#  true in the second rv indicates "don't know"
#  neither of these conditions should occur

sub findAFi {
  my($af,$pa) = @_;
  my @pa = unpack('C2',$pa);
  my $pai;
  for ($pai = 0; $pai < 2; $pai++) {
    last if $pa[$pai] == $af;
  }
  my $unsure = 0;
  unless ($pai) {               # if $pai is zero
    $unsure = 1 if $pa[0] == $pa[1];
  }
  return wantarray
	? ($pai,$unsure)
	: $pai;
}

my($af_index,$unsure) = findAFi(AF_INET(),
	scalar sockaddr_in(1,INADDR_LOOPBACK()));

sub _af_index {
  return $af_index;
}

@EXPORT_OK = qw(
	open_UDP
	open_udpNB
	open_Listen
	open_listenNB
	connectBlk
	connect_NB
	accept_Blk
	accept_NB
	set_NB
	set_so_linger
	dyn_bind
	inet_aton
	inet_ntoa
	sockaddr_in
	sockaddr_un
	inet_pton
	inet_ntop
	ipv6_aton
	ipv6_n2x
	ipv6_n2d
	INADDR_ANY
	INADDR_BROADCAST
	INADDR_LOOPBACK
	INADDR_NONE
	in6addr_any
	in6addr_loopback	
	AF_INET
	AF_INET6
	havesock6
	isupport6
	pack_sockaddr_in6
	unpack_sockaddr_in6
);

sub TCP {
  return $TCP;
}

sub UDP {
  return $UDP;
}

sub _dummy {
  return wantarray
	? ()
	: undef;
}

sub havesock6 {
  return $havesock6;
}

sub isupport6 {
  return $isupport6;
}

sub open_listenNB {
  my $lsock = &open_Listen;
  return $lsock if $lsock && set_NB($lsock);
  close $lsock if $lsock;
  return undef;
}

sub connectBlk {
  unshift @_,1;
  &_connect;
}

sub  connect_NB {
  unshift @_,0;
  &_connect;
}

sub accept_NB {
  unshift @_,0;
  my @rv = &_accept;
  return @rv if wantarray;
  return $rv[0] if @rv;
  return undef;
}

sub accept_Blk {
  unshift @_,1;
  my @rv= &_accept;
  return @rv if wantarray;
  return $rv[0] if @rv;
  return undef;
}

sub set_so_linger {
  my ($FH,$sec) = @_;
  setsockopt($FH,SOL_SOCKET(),SO_LINGER(),pack("ll",1,$sec));
}

sub DESTROY {};

1;

__END__

=head1 NAME

Net::NBsocket -- Non-Blocking Sockets

=head1 SYNOPSIS

  use Net::NBsocket qw(
	open_UDP
	open_udpNB
	open_Listen
	open_listenNB
	connectBlk
	connect_NB
	accept_Blk
	accept_NB
	set_NB
	set_so_linger
	dyn_bind
	inet_aton
	inet_ntoa
	sockaddr_in
	sockaddr_un
	inet_pton
	inet_ntop
	ipv6_aton
	ipv6_n2x
	ipv6_n2d
	INADDR_ANY
	INADDR_BROADCAST
	INADDR_LOOPBACK
	INADDR_NONE
	AF_INET
	AF_INET6
	in6addr_any
	in6addr_loopback	
	havesock6
	isupport6
	pack_sockaddr_in6
	unpack_sockaddr_in6
  );

  $sock = open_UDP($af_family);
  $sock = open_udpNB($af_family);
  DEPRECATED $sock = bind2pp($sock,$port_path,$netaddr);
  $listener = open_Listen($port_path,$netaddr,$af_family);
  $listener = open_listenNB($port_path,$netaddr,$af_family);
  $client = connectBlk($port_path,$netaddr,$af_family);
  $client = connect_NB($port_path,$netaddr,$af_family);
  ($sock,$netaddr) = accept_Blk($srvsock);
  ($sock,$netaddr) = accept_NB($srvsock);
  $rv = set_NB($sock);
  $rv = set_so_linger($sock,$seconds);
  $port = dyn_bind($sock,$netaddr);

	IPv4
  $netaddr = inet_aton($dot_quad);
  $dot_quad = inet_ntoa($netaddr);
  $sin = sockaddr_in($port,$netaddr);
  ($port,$netaddr) = sockaddr_in($sin);
  $sun = sockaddr_un($path);
  ($path) = sockaddr_un($sun);

	IPv6
  $netaddr = inet_pton($AF_family,$text_addr);
  $text_addr = inet_ntop($AF_family,$netaddr);
  $ipv6naddr = ipv6_aton($ipv6_text);
  $hex_text = ipv6_n2x($ipv6naddr);
  $dec_text = ipv6_n2d($ipv6naddr);

	CONSTANTS
  $constant = INADDR_ANY();
  $constant = INADDR_BROADCAST();
  $constant = INADDR_LOOPBACK();
  $constant = INADDR_NONE();
  $constant = AF_INET();
  $constant = AF_INET6();
  $constant = in6addr_any();
  $constant = in6addr_loopback();

	IPv6 conditional
  $trueif = havesock6();
  $trueif = isupport6();
  $sockaddr_in6_struct=pack_sockaddr_in6($port,ipv6naddr);
  ($port,$ipv6naddr)=unpack_sockaddr_in6($sockaddr_in6_struct);

=head1 DESCRIPTION

B<Net::NBsocket> provides a wrapper for B<Socket> and B<Socket6> 
to supply Non-Blocking sockets of various flavors;

=head2 FUNCTIONS

=item * $sock = open_UDP();

Open an unbound UDP socket as below.

=item * $sock = open_udpNB();

Open and return an unbound  non-blocking UDP socket object

  input:	[optional] address family (required for IPv6)
  returns:	pointer to socket object
		or undef on failure

=cut

sub open_UDP {
  my $AF = shift;
  $AF = AF_INET() unless $AF;
  my $usock = do { local *SOCK; };
  return ($usock) if socket($usock,$AF,SOCK_DGRAM(),UDP());
  close $usock if $usock;
  return undef;
}

sub open_udpNB {
  my $AF = shift;
  $AF = AF_INET() unless $AF;
  my $usock = do { local *SOCK; };
  return $usock if socket($usock,$AF,SOCK_DGRAM(),UDP()) && set_NB($usock);
  close $usock if $usock;
  return undef;
}

=item * DEPRECATED $sock=bind2pp($sock,$port_path,$netaddr);

Bind to $port_path and an optional IPv4 bind address as returned by inet_aton
(defaults to INADDR_ANY).

  input:	port or unix domain socket path,
		[optional] bind address
  returns:	socket on sucess, else undef;

Author's note: This function was not well thought out and is now deprecated. It may be
removed in future versions and is no longer in the EXPORT_OK array though it
is still in the module and may be accessed with Net::NBsocket::bind2pp();

Does not support IPv6

=cut

sub bind2pp {		# DEPRECATED, no longer used
  my ($sock,$port_path,$addr) = @_;
  $addr = INADDR_ANY() unless $addr;
  my $path = ($port_path && $port_path =~ /[\D\s]/) ? $port_path : undef;
  my $ok;
  if ($path) {
    unlink $path if -e $path && -S $path;
    $ok = bind($sock,sockaddr_un($path));
  } else {
    $ok = bind($sock,sockaddr_in($port_path,$addr));
  }
  return $sock if $ok;
  close $sock;
  return undef;
}

=item * $listener = open_Listen($port_path,$netaddr,$af_family);

Open a blocking TCP listner as below.

=item * $listener = open_listenNB($port_path,$netaddr,$af_family);

Open and return a non-blocking TCP listener bound to $port_path and an
optional IPv4 or IPv6 bind address as returned by inet_pton 
(defaults to INADDR_ANY or in6addr_any for AF_INET6).

Opens a unix-domain socket if port_path is a path instead of a number.

The user must set the appropriate UMASK prior to calling this routine.

  input:	port or unix domain socket path,
		[optional] bind address
		[optional] address family, default AF_INET
  returns:	pointer to listening socket
		object or undef on failure

=cut

sub open_Listen {
  my ($port_path,$addr,$AF) = @_;
  $AF = AF_INET() unless $AF;
  return undef if $AF == AF_INET6() && ! isupport6();
  unless ($addr) {
    if ($AF == AF_INET6()) {
      $addr = in6addr_any();
    } else {
      $addr = INADDR_ANY();
    }
  }
  if ($AF == AF_INET6()) {
    return undef unless length($addr) == 16;
  } else {
    return undef unless length($addr) == 4;
  }
  my $lsock = do { local *SOCK; };
  my $sockok;
  if ($port_path && $port_path =~ /[\D\s]/) {
    return undef unless socket($lsock,AF_UNIX(),SOCK_STREAM(),0);
    $sockok = setsockopt($lsock,SOL_SOCKET(),SO_REUSEADDR(),pack("l", 1));
    if ($sockok) {
      unlink $port_path if -e $port_path && -S $port_path;
      $sockok = bind($lsock,sockaddr_un($port_path));
    }
  } else {
    return undef unless socket($lsock,$AF,SOCK_STREAM(),TCP());
    $sockok = setsockopt($lsock,SOL_SOCKET(),SO_REUSEADDR(),pack("l", 1));
    if ($sockok) {
      if ($AF == AF_INET6()) {
        $sockok = bind($lsock,pack_sockaddr_in6($port_path,$addr));
      } else {
        $sockok = bind($lsock,sockaddr_in($port_path,$addr));
      }
    }
  }
  return $lsock if $sockok &&
        listen($lsock,SOMAXCONN());
  close $lsock if $lsock;
  return undef;
}

=item * $client = connectBlk($port_path,$netaddr,$af_family);

Begin a blocking TCP connection as below.

=item * $client = connect_NB($port_path,$netaddr,$af_family);

Begin a non-blocking TCP connection to the host designated by $netaddr on
$port_path, or to the unix domain socket designated by the path in $port_path.
$netaddr is unused for unix domain sockets.


  input:	port number or unix domain socket path,
		netaddr as returned by inet_aton,
		[optional] address family (default AF_INET)
  returns:	socket object or
		undef on failure

=cut

sub _connect {
  my($block,$port_path,$netaddr,$AF) = @_;
  $AF = AF_INET() unless $AF;
  my $csock = do { local *SOCK; };
  my $daddr;
  my $proto = TCP();
  return undef unless $port_path;
  if ($port_path =~ /\D/) {
    $daddr = sockaddr_un($port_path);
    $proto = 0;
    $AF = AF_UNIX();
  }
  elsif ($AF == AF_INET6()) {
    return undef unless length($netaddr) == 16;
    $daddr = pack_sockaddr_in6($port_path,$netaddr);
  } else {
    return undef unless length($netaddr) == 4;
    $daddr = sockaddr_in($port_path,$netaddr);
  }
  return undef unless $daddr && socket($csock,$AF,SOCK_STREAM(),$proto);
  if ($block || set_NB($csock)) {
    return $csock if connect($csock,$daddr) || $! == EINPROGRESS();
  }
  close $csock;
  return undef;
}

=item * ($sock,$netaddr) = accept_Blk($srvsock);

Accept a connection and return a BLOCKING socket as below.

=item * ($sock,$netaddr) = accept_NB($srvsock);

Accept a connection from a remote client, return a non-blocking socket
and the network address of the remote host as returned by inet_aton or
the unix domain socket path if PF_INET or PF_UNIX respectively.

  input:	listening socket object
  returns:	client socket object,
		client packed netaddr or
		unix domain socket path

	on failure returns and empty array or undef

=cut

sub _accept {
  my($block,$server) = @_;
  return () unless $server;
  my $clone = do { local *SOCK; };
  my $paddr = eval { undef local $^W; accept($clone,$server)};
  return () unless $paddr;		# attempted accept with no client

  my @aftry = unpack('C2',$paddr);
  my $af = $aftry[_af_index()];		# get address family

  my($port_path,$netaddr);
  if ($af == AF_INET()) {
    ($port_path,$netaddr) = sockaddr_in($paddr);
  }
  elsif ($af == AF_INET6()) {
    ($port_path,$netaddr) = unpack_sockaddr_in6($paddr);
  }
  else {	# all that is left is unix domain sockets
    $netaddr = sockaddr_un($paddr);
  }
  return ($clone,$netaddr)
	if $netaddr && ($block || set_NB($clone));
  close $clone;
  return ();
}

=item * $rv = set_NB($sock);

Set a socket to Non-Blocking mode

  input:	SOCK object pointer
  returns:	true on success or
		undef on failure

=cut

sub set_NB {
  my $sock = shift;
  if (defined $POSIX::{F_GETFL}) {
    my $flags = fcntl($sock,F_GETFL(),0);
    fcntl($sock,F_SETFL(),$flags | O_NONBLOCK())
  } else {	# must be a windows box
#    my $FIONBIO = 0x8004667e;
    ioctl($sock,0x8004667e,1);
  }
}

=item $rv = set_so_linger($sock,$seconds);

  Set SO_LINGER on top level socket

  input:        sock object pointer, seconds
  returns:      true = success, false = fail

=cut

=item * $port = dyn_bind($sock,$netaddr,$af_family);

Attempt to bind a socket to the IP address and randomly assigned
port number, in the range 49152 through 65535. Fails after 100 attempts

  input:	socket
		netaddr as returned by inet_pton
  returns:	port number or undef

=cut

sub dyn_bind {  # t => s_make_kid_Dbind.t
  my($sock,$netaddr) = @_;
  my $v6 = length($netaddr) == 16
	? 1 : 0;
  foreach(1..100) {
    my $port = 49152 + int rand(65536 - 49152);
    unless ($v6) {
      return $port if bind($sock,sockaddr_in($port,$netaddr));
    } else {
      return $port if bind($sock,pack_sockaddr_in6($port,$netaddr));
    }
  }
  return undef;
}

=head2 IPv4 exported from B<Socket>

=item * $netaddr = inet_aton($dot_quad);

Takes an argument of a hostname or dot quad ip address and returns a four octet packed network address.

=item * $dot_quad = inet_ntoa($netaddr);

Takes a 4 octet packed network address and returns a dot quad text string. Throws an error if fed a non-standard argument.

=item * $sin = sockaddr_in($port,$netaddr);

In SCALAR context, takes a port number and an IPv4 network address and returns a sockaddr_in structure.

=item * ($port,$netaddr) = sockaddr_in($sin);

In ARRAY context, takes a sockaddr_in structure and return the port and network address

=item * $sun = sockaddr_un($path);

In SCALAR context, takes its pathname and returns a sockaddr_un structure.

=item * ($path) = sockaddr_un($sun);

In ARRAY context, takes a sockaddr_un structure and returns its pathname.

=head2 IPv6 exported from B<Socket6> & B<NetAddr::IP::InetBase>

=item * $netaddr = inet_pton($AF_family,$text_addr);

This function takes a dot quad IPv4 address or an RFC 1884 text IPv6 address and returns a 4 or 16 octet network address depending on the AF family argument.

=item * $text_addr = inet_ntop($AF_family,$netaddr);

This function takes a 4 or 16 octet network address depending on the AF family argument and returns a IPv4 dot quad or IPv6 text address respectively.

=item * $ipv6naddr = ipv6_aton($ipv6_text);

This function takes an RFC 1884 IPv6 text address and returns a 16 octet IPv6 network address.

=item * $hex_text = ipv6_n2x($ipv6naddr);

This function takes an IPv6 network address and returns an IPv6 hex text address.
Throws an error if fed a non-standard argument.

=item * $dec_text = ipv6_n2d($ipv6naddr);

This function takes an IPv6 network address and returns and IPv6 text address with the last two octets in IPv4 dot quad representation.

=head2 CONSTANTS

=item * $constant = INADDR_ANY(); INADDR_ANY;

This constant returns the wildcard address, equivalent to inet_aton('0.0.0.0');

=item * $constant = INADDR_BROADCAST();	INADDR_BROADCAST;

This constant returns the wildcard address, equivalent to inet_aton('255.255.255.255');

=item * $constant = INADDR_LOOPBACK(); INADDR_LOOPBACK;

This constant returns the LOCALHOST address, equivalent to inet_aton('127.0.0.1');

=item * $constant = INADDR_NONE(); INADDR_NONE;

This constant returns the C<invalid> address, equivalent to inet_aton('255.255.255.255');

=item * $constant = AF_INET(); AF_INET;

This constant returns the AF_INET family number.

=item * $constant = AF_INET6(); AF_INET6;

This constant retunrs the AF_INET6 family number for this operating system.

=item * $constant = in6addr_any(); in6addr_any;

This constant returns the IPv6 16 octet wildcard address, equivalent to ipv6_aton('::0');

=item * $constant = in6addr_loopback(); in6addr_loopback;

This constant returns the IPv6 16 octet LOCALHOST address, equivalent to ipv6_aton('::1');

=head2 IPv6 Conditional

=item * $trueif = havesock6();

This function returns TRUE if Socket6 is loaded on this host, else returns FALSE.

=item * $trueif = isupport6();

This function returns TRUE if Socket6 is loaded on this host and the underlying operating system suports IPv6 sockets, else returns FALSE.

=item * $sockaddr_in6_struct=pack_sockaddr_in6($port,ipv6naddr);

If Socket6 is loaded on this host, in SCALAR context, takes a port number and an IPv6 network address and returns a sockaddr_in6 structure.
If Socket6 is not loaded, returns C<undef>.

=item * ($port,$ipv6naddr)=unpack_sockaddr_in6($sockaddr_in6_struct);

If Socket6 is loaded on this host, in ARRAY context, takes a sockaddr_in6 structure and returns the port number and IPv6 netaddr.
If Socket6 is not loaded, returns and empty array.

=head1 DEPENDENCIES

	POSIX
	Socket
	NetAddr::IP

=head1 EXPORT_OK

	open_UDP
	open_udpNB
	open_Listen
	open_listenNB
	connectBlk
	connect_NB
	accept_Blk
	accept_NB
	set_NB
	set_so_linger
	dyn_bind
	inet_aton
	inet_ntoa
	sockaddr_in
	sockaddr_un
	inet_pton
	inet_ntop
	ipv6_aton
	ipv6_n2x
	ipv6_n2d
	INADDR_ANY
	INADDR_BROADCAST
	INADDR_LOOPBACK
	INADDR_NONE
	in6addr_any
	in6addr_loopback	
	AF_INET
	AF_INET6
	havesock6
	isupport6
	pack_sockaddr_in6
	unpack_sockaddr_in6

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 COPYRIGHT 2004 - 2014

Michael Robinton

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the

        Free Software Foundation, Inc.
        59 Temple Place, Suite 330
        Boston, MA  02111-1307, USA

or visit their web page on the internet at:

        http://www.gnu.org/copyleft/gpl.html.

=head1 SEE ALSO

L<POSIX>, L<Socket>

=cut

1;
