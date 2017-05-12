# $Id: //eai/perl5/Rstat-Client/2.2/src/distro/Client.pm#2 $

package Rstat::Client;

use strict;
use Socket;
use IO::Socket;
use IO::Select;

use vars qw($VERSION);

$VERSION = '2.2';

#####
#
# Constructor
#
#####

sub new {

  my $proto = shift;
  my $class = ref ($proto) || $proto;

  my $host  = shift;

  my $self  = { 'host' => $host || 'localhost' };

  bless $self, $class;
  return $self;

}

#####
#
# Private functions
#
#####

#
# Return a random 32-bit integer suitable for use as an RPC
# transaction id
#

sub _make_xid { int rand 0xffffffff }

#
# Send a UDP request to the given host/port, and return a reply (with
# optional timeout)
#

sub _udp_request {

  my ($host, $port, $request, $timeout) = @_;

  my $sock = IO::Socket::INET->new
    (Proto => 'udp')                      or do { $@ = "Socket: $!";  return };

  my ($raddr, $rport) = IO::Socket::INET::_sock_info ($host, $port);

  my $hosterr = "Unknown host '$host'";
  my ($rhost) =
    $sock->_get_addr ($raddr)             or do { $@ = $hosterr;      return };

  my $peer = pack_sockaddr_in ($rport, $rhost);
  my $sent = $sock->send ($request, 0, $peer);

  defined ($sent)                         or do { $@ = "Send: $!";    return };

  my $select = IO::Select->new ($sock);
  $select->can_read ($timeout)            or do { $@ = "Timeout\n";   return };

  my $rcvd = $sock->recv (my $reply, 1024);

  defined ($rcvd)                         or do { $@ = "Receive: $!"; return };

  $sock->close;
  return $reply;

}

#
# Ask the portmapper for the port on which the rstatd service listens
#

sub _get_port {

  my ($host, $timeout) = @_;

  my $xid = _make_xid;

  my @request =
    (
     $xid,        # transaction id
     0x00000000,  # request type (CALL)
     0x00000002,  # rpc version
     0x000186a0,  # program (portmap)
     0x00000002,  # version
     0x00000003,  # procedure
     0x00000000,
     0x00000000,
     0x00000000,
     0x00000000,
     0x000186a1,  # program to look up (rstat)
     0x00000003,  # version
     0x00000011,  # protocol (UDP)
     0x00000000
    );

  my $request = pack "N*", @request;
  my $reply   = _udp_request ($host, 'sunrpc(111)', $request, $timeout)
    or return;

  my @reply   = unpack "N*", $reply;

  (shift @reply == $xid) or do { $@ = "Transaction id mismatch\n";   return };
  (shift @reply == 0x01) or do { $@ = "Invalid reply\n";             return };
  (shift @reply == 0x00) or do { $@ = "Portmapper request failed\n"; return };

  my $port = pop @reply  or do { $@ = "rstatd service not found\n";  return };

  return $port;

}

#####
#
# Public methods
#
#####

#
# Make the rstat request, with optional timeout
#

sub fetch {

  my ($self, $timeout) = @_;

  my $port = _get_port ($self->{host}, $timeout) or return;
  my $xid  = _make_xid;

  my @request =
    (
     $xid,        # transaction id
     0x00000000,  # request type (CALL)
     0x00000002,  # rpc version
     0x000186a1,  # program (rstat)
     0x00000003,  # version
     0x00000001,  # procedure
     0x00000000,
     0x00000000,
     0x00000000,
     0x00000000
    );

  my $request = pack "N*", @request;
  my $reply   = _udp_request ($self->{host}, $port, $request, $timeout)
    or return;

  my @reply   = unpack "N*", $reply;

  (shift @reply == $xid) or do { $@ = "Transaction id mismatch\n";   return };
  (shift @reply == 0x01) or do { $@ = "Invalid reply\n";             return };
  (shift @reply == 0x00) or do { $@ = "rstat request failed\n";      return };

  shift @reply for (1..3);

  my $stats = {};

  $stats->{'cp_time'}->[0]     = shift @reply;
  $stats->{'cp_time'}->[1]     = shift @reply;
  $stats->{'cp_time'}->[2]     = shift @reply;
  $stats->{'cp_time'}->[3]     = shift @reply;

  $stats->{'dk_xfer'}->[0]     = shift @reply;
  $stats->{'dk_xfer'}->[1]     = shift @reply;
  $stats->{'dk_xfer'}->[2]     = shift @reply;
  $stats->{'dk_xfer'}->[3]     = shift @reply;

  $stats->{'v_pgpgin'}         = shift @reply;
  $stats->{'v_pgpgout'}        = shift @reply;
  $stats->{'v_pswpin'}         = shift @reply;
  $stats->{'v_pswpout'}        = shift @reply;
  $stats->{'v_intr'}           = shift @reply;
  $stats->{'if_ipackets'}      = shift @reply;
  $stats->{'if_ierrors'}       = shift @reply;
  $stats->{'if_oerrors'}       = shift @reply;
  $stats->{'if_collisions'}    = shift @reply;
  $stats->{'v_swtch'}          = shift @reply;

  $stats->{'avenrun'}->[0]     = (shift @reply) / 256;
  $stats->{'avenrun'}->[1]     = (shift @reply) / 256;
  $stats->{'avenrun'}->[2]     = (shift @reply) / 256;

  $stats->{'boottime.tv_sec'}  = shift @reply;
  $stats->{'boottime.tv_usec'} = shift @reply;
  $stats->{'curtime.tv_sec'}   = shift @reply;
  $stats->{'curtime.tv_usec'}  = shift @reply;

  $stats->{'if_opackets'}      = shift @reply;

  return $stats;

}

1;

__END__

=head1 NAME

Rstat::Client - Perl library for client access to rstatd

=head1 SYNOPSIS

  use Rstat::Client;
  
  $clnt  = Rstat::Client->new("some.host")
  
  $stats = $clnt->fetch();    # wait for response
  $stats = $clnt->fetch(10);  # fetch with timeout
  
  printf "CPU Load: %.2f %.2f %.2f\n", @{$stats->{'avenrun'}};

=head1 DESCRIPTION

This Perl library gives you access to rstatd statistics. First create
an C<Rstat::Client> object:

  $clnt = Rstat::Client->new($hostname);

The parameter C<$hostname> is optional and defaults to localhost. The
constructor never fails; a valid C<Rstat::Client> object is always
returned.

Fetch statistic records by calling the C<fetch()> method of the
C<Rstat::Client> object:

  $stats = $clnt->fetch($timeout) or die $@;

The parameter C<$timeout> is optional. By default, the C<fetch()>
method will block until a response is returned.

If the request is successful, C<fetch()> returns a reference to a hash
containing the statistics. In the event of an error, C<fetch()>
returns C<undef>, and C<$@> contains the reason for failure.

=head1 DATA FORMAT

Here is a commented C<Data::Dumper> dump of the stats hash:

  $stats = {
    # time when this record was fetched
    'curtime.tv_sec' => '1021885390',
    'curtime.tv_usec' => 181205,
  
    # time when the system was booted
    'boottime.tv_sec' => '1021781411',
    'boottime.tv_usec' => '0',
  
    # pages swapped in/out
    'v_pswpin' => 1,
    'v_pswpout' => '0',
  
    # pages paged in/out
    'v_pgpgin' => 43155,
    'v_pgpgout' => 64266,
  
    # interrupts and context switches
    'v_intr' => 11150229,
    'v_swtch' => 23174363,
  
    # network statistics (sum over all interfaces)
    'if_ipackets' => 43238686,
    'if_ierrors' => 71633,
    'if_opackets' => '87451',
    'if_oerrors' => '0',
    'if_collisions' => 0,
  
    # run queue length (1/5/15 minutes average)
    'avenrun' => [
      '0.45703125',
      '0.21875',
      '0.13671875'
    ],
  
    # cpu time (in ticks) for USER/NICE/SYS/IDLE
    'cp_time' => [
      261982,
      11,
      450845,
      9685071
    ],
  
    # disk transfers
    'dk_xfer' => [
      47053,
      '0',
      '0',
      '0'
    ],
  };

=head2 NOTES

Timestamps are separated into seconds (standard UNIX time) and
microseconds. The availability of a current timestamp allows proper
calculation of the interval between measurements without worrying
about network latency.

Most values are counters. To get the real numbers you have to
C<fetch()> samples regularly and divide the counter increments
by the time interval between the samples.

The C<cpu_time> array holds the ticks spent in the various CPU states
(averaged over all CPUs). If you know the regular tick rate of the target
system you may calculate the number of CPUs from the sum of C<cpu_time>
increments and the time interval between the samples. Most often you
will be interested in the percentage of CPU states only.

The C<avenrun> array is originally shifted by 8 bits. C<Rstat::Client>
takes care of this and returns floating point values.

=head1 PORTABILITY

As of version 2.0, this library is written in pure Perl and should
work on any platform. It has been tested from Linux, Solaris and
Microsoft Windows clients, talking to rstat servers running on Linux
and Solaris.

=head1 BUGS AND DESIGN LIMITATIONS

For portability reasons this package uses version 3 (RSTATVERS_TIME)
of the rstatd protocol. Version 4 adds dynamically sized arrays for CPU
state and disk access but was not available on all targeted plattforms.

As any software this package may contain bugs. Please feel free to
contact the author if you find one.

=head1 AUTHOR / COPYRIGHT

=head2 Version 2.0 and Later, Including This Version

Ron Isaacson <ron.isaacson@morganstanley.com>

Copyright (c) 2008, Morgan Stanley & Co. Incorporated

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License,
version 2, as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License, version 2 for more details.

A copy of the GNU General Public License was distributed with this
program in a file called LICENSE. For additional copies, write to
the Free Software Foundation, Inc., 51 Franklin Street, Fifth
Floor, Boston, MA 02110-1301 USA.

THE FOLLOWING DISCLAIMER APPLIES TO ALL SOFTWARE CODE AND OTHER
MATERIALS CONTRIBUTED IN CONNECTION WITH THIS SOFTWARE:

THIS SOFTWARE IS LICENSED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE AND ANY
WARRANTY OF NON-INFRINGEMENT, ARE DISCLAIMED. IN NO EVENT SHALL
THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. THIS SOFTWARE
MAY BE REDISTRIBUTED TO OTHERS ONLY BY EFFECTIVELY USING THIS OR
ANOTHER EQUIVALENT DISCLAIMER AS WELL AS ANY OTHER LICENSE TERMS
THAT MAY APPLY.

=head2 Version 1.2 and Earlier

Axel Schwenke <axel.schwenke@gmx.net>

Copyright (c) 2002 Axel Schwenke. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 VERSION

Version 2.2 (April 16, 2008)

=head1 SEE ALSO

L<rstatd(8)>

=cut
