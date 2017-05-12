# Copyright (C) 2009 by Carnegie Mellon University
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, as published by
# the Free Software Foundation, under the terms pursuant to Version 2,
# June 1991.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

package Net::Ncap;

use 5.008000;
use strict;
use warnings;
use Carp;

our $VERSION = '1.01';

use FileHandle;

use XSLoader;
XSLoader::load('Net::Ncap', $VERSION);

sub _pnum { (getprotobyname(shift))[-1] }

use constant IPV4   => _pnum('ip');
use constant IPV6   => _pnum('ipv6');
use constant ICMPV6 => _pnum('icmp');
use constant ICMP   => _pnum('ipv6-icmp');
use constant UDP    => _pnum('udp');
use constant TCP    => _pnum('tcp');

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  my $maxmsg = @_ ? shift : 70000;
  $self->{ncap}   = Net::Ncap::ncap->new($maxmsg);
  $self->{files}  = {};
  $self->{ifaces} = {};
  return $self;
}

sub _add_fh {
  my $self = shift;
  my $fh = shift;
  my $v = [$fh, @_];
  for my $k ($fh, @_) {
    $self->{files}->{$k} = $v;
  };
  $fh;
}

sub _drop_fh {
  my($self, $fh) = @_;
  delete $self->{files}->{$_} foreach @{$self->{files}->{$fh}};
}

sub _add_ino {
  my($self, $ino, $label) = @_;
  die "invalid file handle '$ino'\n" unless defined $ino;
  $self->{ifaces}->{$ino}   = $ino;
  $self->{ifaces}->{$label} = $ino;
}

sub _drop_ino {
  my($self, $ino) = @_;
  delete $self->{ifaces}->{$_} foreach @{$self->{ifaces}->{$ino}};
}

sub _fh {
  my $self = shift;
  my $name = shift;
  my $mode = shift || '<';
  FileHandle->new($name, $mode) or die "problem opening $name ($mode) : $!\n";
}

sub _handle {
  my($self, $res) = @_;
  if (! defined $res) {
    my $msg = $self->{ncap}->errstr;
    die "ncap failure: $msg\n";
  }
  $res;
}

sub add_if {
  my $self = shift;
  my($name, $bpf, $promisc, $vlans) = @_;
  if (! defined $promisc) {
    $promisc = 1;
  }
  $vlans ||= [];
  my $fno = $self->_handle(
    $self->{ncap}->add_if($name, $bpf, $promisc,
                          $vlans, scalar @$vlans));
  $self->_add_ino($fno, $name);
}

sub drop_if {
  my($self, $ino) = @_;
  $self->_handle($self->{ncap}->drop_if($ino));
  $self->_drop_ino($ino);
}

sub add_nf {
  my($self, $file, $label) = @_;
  my $fh = ref $file ? $file : $self->_fh($file);
  $label = $file unless defined $label;
  $self->_handle($self->{ncap}->add_nf($fh, $label));
  $self->_add_fh($fh, $label);
}

sub drop_nf {
  my($self, $fh) = @_;
  $self->_handle($self->{ncap}->drop_nf($fh));
  $self->_drop_file($fh);
}

sub add_pf {
  my($self, $fh, $label) = @_;
  $fh = ref $fh ? $fh : $self->_fh($fh);
  $label = $fh->fileno unless defined $label;
  $self->_handle($self->{ncap}->add_pf($fh, $label));
  $self->_add_file($fh, $label);
}

sub drop_pf {
  my($self, $fh) = @_;
  $self->_handle($self->{ncap}->drop_pf($fh));
  $self->_drop_file($fh);
}

sub add_dg {
  my($self, $socket, $label) = @_;
  $self->_handle($self->{ncap}->add_dg($socket, $label));
  $label = $socket->fileno unless ref $label;
  $self->_add_ino($socket, $label);
}

sub drop_dg {
  my($self, $socket) = @_;
  $self->_handle($self->{ncap}->drop_dg($socket));
  $self->_drop_ino($socket);
}

sub filter {
  my $self = shift;
  $self->_handle($self->{ncap}->filter(@_));
}

sub collect {
  my($self, $callback) = splice(@_, 0, 2);
  my %opt = @_;
  my $polling    = $opt{polling}    || 0;
  my $timeout    = $opt{timeout}    || 0;
  my $timeout_cb = $opt{timeout_cb} || undef;
  my $sigwrap    = $opt{sigwrap}    || $timeout;
  my $cb = sub {
    if ($timeout_cb && ! defined $_[-1]) {
        $timeout_cb->();
    }
    else {
      $callback->(@_);
    }
  };
  $self->_handle(
    $sigwrap ? $self->{ncap}->collect_sighandle($polling, $timeout, $cb, $self)
             : $self->{ncap}->collect($polling, $cb, $self)
  );
}

sub stop {
  my $self = shift;
  $self->_handle($self->{ncap}->stop(@_));
}

sub write {
  my $self = shift;
  $self->_handle($self->{ncap}->write(@_));
}

sub send {
  my $self = shift;
  $self->_handle($self->{ncap}->send(@_));
}

###

package Net::Ncap::ncap_msg; {

# extending the XS interface

use strict;
use warnings;

use constant IPV4 => Net::Ncap::IPV4;
use constant IPV6 => Net::Ncap::IPV6;

sub _ipv4_unpack { unpack('W4', shift) }
sub _ipv6_unpack { unpack('n8', shift) }

sub src {
  my $self = shift;
  my $np = $self->nproto;
  return [_ipv4_unpack($self->src_packed)] if $np == IPV4;
  return [_ipv6_unpack($self->src_packed)] if $np == IPV6;
  die "unknown network protocol '$np'\n";
}

sub dst {
  my $self = shift;
  my $np = $self->nproto;
  return [_ipv4_unpack($self->dst_packed)] if $np == IPV4;
  return [_ipv6_unpack($self->dst_packed)] if $np == IPV6;
  die "unknown network protocol '$np'\n";
}

sub _ipv4_str { join('.',                       @{shift()}) }
sub _ipv6_str { join(':', map { sprintf("%X") } @{shift()}) }

sub sip {
  my $self = shift;
  my $np = $self->nproto;
  return _ipv4_str($self->src) if $np == IPV4;
  return _ipv6_str($self->src) if $np == IPV6;
  die "unknown network protocol '$np'\n";
}

sub dip {
  my $self = shift;
  my $np = $self->nproto;
  return _ipv4_str($self->dst) if $np == IPV4;
  return _ipv6_str($self->dst) if $np == IPV6;
  die "unknown network protocol '$np'\n";
}

sub nname { (getprotobynumber(shift->nproto))[0] }
sub tname { (getprotobynumber(shift->tproto))[0] }

sub payload_ref { \(shift->payload) }


}

###

1;

__END__

=head1 NAME

Net::Ncap - Perl extension for the ncap(3) network data capture library.

=head1 SYNOPSIS

  use Net::Ncap;
  use Net::DNS::Packet;
  use FileHandle;

  # output file
  my $fh = FileHandle->new('swag.ncap', '>');

  # create ncap object
  my $nc = Net::Ncap->new;

  # add a filter specification
  $ncap->filter('dns');

  # add a network interface for live listening
  $ncap->add_if(shift || 'eth0');

  # define the callback
  sub cb {
    my $m = shift;

    # save to ncap file
    $ncap->write($m, $fh);

    # example of parsing packet
    my $pkt = Net::DNS::Packet->new($m->payload_ref) || return;
    my $q = ($pkt->question)[0];
    my @answers = $pkt->answer;
    print join(',',
      $m->sec,   $m->nsec,
      $m->sip,   $m->dip,
      $m->sport, $m->dport,
      $q->qtype, $q->qname,
      @answers ? join(' -- ', map { $_->string } @answers) : ()
    ), "\n";
  }

  # collect the data
  $nc->collect(\&cb);


=head1 DESCRIPTION

Net::Ncap is a Perl binding to the ncap(3) network data capture library.
The ncap documentation describes itself thusly:

      The ncap library is a high level interface for network
      data capture. The source of network data can be either
      live traffic or files containing previously captured or
      generated data. Files can be in ncap format or in pcap(3)
      format, and can be either normal binary files or network
      sockets.

=head1 CONSTRUCTOR

=over 4

=item new([maxmsg])

Creates a new Net::Ncap object. Methods are dispatched to their
corresponding functions provided by the ncap library.

The optional parameter I<maxmsg> determines the maximum size of an ncap
payload that the library is willing to process (default 70000).

=back

=head1 METHODS

The following methods, for the most part, directly correspond to the
functions provided by the ncap library. See L<ncap(3)> for more details
on what these functions do.

=over 4

=item add_if($name, [$bpf], [$promisc], [$vlans])

Adds a network interface as a data source. The I<name> of the interface
is required (e.g. 'eth0'). A BPF program can be provided as a string
with the I<bpf> parameter (unless an NCAP filter has been provided via
the filter() method). I<promisc> determines whether or not the interface
is opened in promiscuous mode (default 0). An optional array refererence
to VLANs may also be provided for filtering based on tagged
802.1Q frames.

=item drop_if($name)

Removes the given network interface from the collection pool.

=item add_nf($file, [$label])

Adds the given NCAP file as a data source. If I<file> is a reference, it
is assumed to be an open file handle and is used directly. Otherwise it
is assumed to be a file name and is opened for reading. An optional
I<label> can be provided for this source; by default the label is either
the filename or file number, depending on what was provided in I<file>.

=item drop_nf($file)

Removes the given NCAP file as a data source. The provided I<file> can
either be the file name, handle, or label (if one was provided).

=item add_pf($file, [$label])

Adds the given PCAP file as a data source. I<file> can either be a file
name or a file handle. Otherwise identical to add_nf(), including
accepting an optional I<label>.

=item drop_pf($file)

Removes the given PCAP file as a data source. The provided I<file> can
either be the file name, handle, or label (if one was provided).

=item add_dg($socket)

Adds the given socket handle as a data source.

=item drop_dg($socket)

Removes the given socket handle as a data source.

=item filter($filter)

Installs an NCAP filter described by the given string. If any BPFs
(berkely packet filters) have been installed, this will fail.

=item collect($callback, [%opts])

Collect data from the collection pool, invoking the subroutine
referenced by I<callback> for each matching ncap message. There are
several named options available:

=over 4

=item polling

Controls whether collection happens continuously (the default) or once.

=item sigwrap

Disabled by default. Controls whether signal handlers are installed for
SIGHUP, SIGINT, and SIGTERM prior to passing control to the collection
loop. Perl only sees these events when it is in context (i.e. during the
callback). Until then they are queued by default, until perl can handle
them. If you are polling on an interface that is not very busy, or if
your filters only occasionally pass an interesting message, it might be
a while before perl gets a chance to handle signals. With this option
enabled, the program is interruptable. Whatever signal handlers were in
place prior to invoking collect are restored once complete.

=item timeout

Disabled by default. Specifies a time window for which your callback
will be invoked, regardless of whether any messages have matched your
filters. In such a case, the message provided to the callback will be
undef. Enabling I<timeout> automatically enables I<sigwrap> as
described above.

=item timeout_cb

Specifies an optional alternate callback reference for I<timeout>
induced callbacks, rather than sending undef to the primary callback.

=back

=item stop()

Halts the collection loop. There might be a few stray callbacks before
the loop actually exits, depending on the granularity configured into
the ncap library.

=item write($fh, [$msg])

Writes the given ncap message to the provided file handle in the ncap
portable binary format. If no message is provided, a proper file header
is written instead.

=item send($socket, [$msg, $flags])

Writes the given ncap message to the provided socket handle in the ncap
portable binary format. If no Net::Ncap::ncap_msg object is provided, an
NCAP file header is written instead. <em>flags<em> are an integer
representation of any flags as would be provided to the send(2) function
from the socket library (default MSG_DONTROUTE).

=back

=head1 CALLBACK

=over 4

=item callback($msg)

The callback function is handed a single parameter, a reference to a
message object. See below for more information. If collection was
invoked with either I<sigwrap> or I<timeout> enabled, the callback
might be invoked with C<undef>, depending on whether I<timeout_cb>
was provided.

The callback can abort the collection loop by invoking the stop() method
on the Net::Ncap object.

=back

=head1 MESSAGE OBJECTS

The callback receives references to Net::Ncap::ncap_msg objects. The
following accessors, for the most part, correspond to the the
information available from the structs comprising an ncap message. See
ncap(3) for more information on the low level format.

=over 4

=item label()

The label associated with this data source. By default this will be the
file name or interface name, unless an alternate label was associated
with the source.

=item src_packed()

The source IP address in packed (network byte order) form. (i.e. either
either a ip_addr or ip6_addr struct).

=item dst_packed()

The destination IP address in packed (network byte order) form.

=item src()

Returns an array reference containing the components of the source IP
address. For IPv4 these represent the four 32 bit quads, for IPv6 these
represent the eight 16-bit components.

=item dst()

Returns an array reference containing the components of the destination
IP address, as above.

=item sip()

The source IP address as a string. For IPv4 this is dotted-quad, for
IPv6 this is colon-hexadecimal.

=item dip()

The destination IP address as a string, as above.

=item sport()

The source port of the datagram. (undef for icmp)

=item dport()

The destination port of the datagram. (undef for icmp)

=item sec()

The seconds component of the datagram timestamp.

=item nsec()

The nanoseconds component of the datagram timestamp.

=item nproto()

The numeric network protocol type (IP or IPV6)

=item tproto()

The numeric transport protocol type (UDP, TCP, or ICMP)

=item nname()

The network protocol name

=item tname()

The transport protocol name

=item payload()

The binary (network format) record (for example, the DNS record)

=item payload_ref()

A scalar reference to the payload string.

=item user1()

User defined value

=item user2()

User defined value

=item type()

The ICMP type of the datagram. (undef for udp/tcp)

=item code()

The ICMP code of the datagram. (undef for udp/tcp)

=item offset()

The TCP offset of the datagram. (undef for icmp/udp)

=item flags()

The TCP flags of the datagram. (undef for icmp/udp)

=back

=head1 SEE ALSO

L<ncap(3)>, L<pcap(3)>, L<Net::Pcap>

The C<Net::Ncap> project page: L<http://tools.netsa.cert.org/wiki/display/tt/Net-Ncap>

The ncap library can be downloaded from: L<ftp://ftp.isc.org/isc/ncap/>

The pcap library can be downloaded from: L<http://www.tcpdump.org/>


=head1 AUTHOR

Matthew Sisk, E<lt>sisk@cert.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Carnegie Mellon University

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License, as published by
the Free Software Foundation, under the terms pursuant to Version 2,
June 1991.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

=cut
