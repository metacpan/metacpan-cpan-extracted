##############################################################################
#
#  Net::BCCN Broadcast Channel Notifications protocol
#  (c) Vladi Belperchinov-Shabanski "Cade" 2026
#  http://cade.noxrun.com <cade@noxrun.com>
#
#  GPL
#
##############################################################################
package Net::BCCN;
use strict;
use POSIX ":sys_wait_h";
use IO::Socket::INET;
use IO::Select;
use Data::Dumper;

our $VERSION = '1.1';

$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = 1;

##############################################################################


# FIXME: sequence in hex?
sub parse_notification_msg_data
{
  my $data = shift;
  return () unless $data =~ /^BCCN(\d+)\[(\d+)(:([a-z_0-9]+)=([a-z_0-9]+))?\]([a-z_0-9\.\?\/]+):(\d+):(\!?[a-z_0-9\.\/]+)\|(.*)/i;

  #        ver  len  cktype  ckval  fr  seq  chan  payload
  return  ( $1,  $2,     $4,    $5, $6,  $7,   $8,     $9 );
}

##############################################################################

# use Sys::Hostname; my $h = hostname();

sub new
{
  my $class = shift;
  $class = ref( $class ) || $class;

  my %opt = @_;

  my $self = {
               NAME    => $opt{ 'NAME'    } || '?',               # local instance name
               ADDR    => $opt{ 'ADDR'    } || '255.255.255.255', # broadcast address
               BIND    => $opt{ 'BIND'    } || '0.0.0.0',         # local bind address
               PORT    => $opt{ 'PORT'    },                      # which UDP port to listen and send on

               DEBUG   => $opt{ 'DEBUG'   }, # debug level, true to enable or positive number for debug level
             };

  $self->{ 'DD'   } = {} if $opt{ 'DD' }; # dedup requested
  $self->{ 'SSS'  } = {} if $opt{ 'SS' }; # speed stats requested
  $self->{ 'SSX'  } =       $opt{ 'SS' }; # max events counting

  $self->{ 'TQMC' } = {}; # total queue messages count

# print Dumper( \%opt, $self );

  bless $self, $class;
  return $self;
}

sub error
{
  my $self = shift;

  return $self->{ 'ERR' };
}

sub open
{
  my $self = shift;

  my $bind = $self->{ 'BIND' };
  my $port = $self->{ 'PORT' };

  my $sock = IO::Socket::INET->new
    (
    Proto     => "udp",
    LocalAddr => $bind,
    LocalPort => $port,
    ReuseAddr => 1,
    Blocking  => 0,
    Broadcast => 1,
    );

  if( ! $sock )
    {
    $self->{ 'ERR' } = "udp socket bind $bind:$port failed: $!";
    return undef;
    }

  $self->{ 'SOCK' } = $sock;

  return 1;
}

sub notify
{
  my $self = shift;

  my $chan = shift;
  my $body = shift;

  my $sock = $self->{ 'SOCK' } or die "error: cannot notify, udp socket not open, call open() first\n";
  $self->{ 'ERR' } = undef;

  my $seq = ++$self->{ 'SQ' }; # send sequence number

  my $name = $self->{ 'NAME' };

  my $msg = "$name:$seq:$chan|$body";
  my $len = length $msg;
  $msg = "BCCN1[$len]$msg";
  $len = length $msg;

  my $to = pack_sockaddr_in( $self->{ 'PORT' }, inet_aton( $self->{ 'ADDR' } ) );

  my $sl = $sock->send( $msg, 0, $to );
  if( ! defined( $sl ) )
    {
    dr_log("ERR: send failed: $!");
    $self->{ 'ERR' } = "send to channel [$chan] failed: $!";
    return undef;
    }

  if( $sl != $len )
    {
    $self->{ 'ERR' } = "send to channel [$chan] error: short send: expected $len, sent $sl bytes";
    return undef;
    }

  return 1;
}


sub __pull_all_available
{
  my $self = shift;
  my $chan = shift;
  my $opt  = shift;

  $self->{ 'ERR' } = undef;

  my $sock = $self->{ 'SOCK' } or die "error: cannot notify, udp socket not open, call open() first\n";
  my $cq   = $self->{ 'Q' }{ $chan } ||= []; # channel queue

  my $to = @$cq ? 0 : $opt->{ 'TIMEOUT' } || 0; # if q has messages, do not wait, just pull whatever waiting

  my $sel = IO::Select->new;
  $sel->add( $sock );

  my $recvc = 0;
  while (1)
    {
    my $msg;

    my @ready = $sel->can_read( $to );
    $to = 0;

    last unless @ready;

    my $from = $sock->recv( $msg, 65535, 0 );

    if( ! defined( $from ) )
      {
      next if $!{ 'EINTR' };
      $self->{ 'ERR' } = "recv failed: $!";
      return undef;
      }

    my ( $from_port, $from_ip4_packed ) = unpack_sockaddr_in( $from );
    my $from_ip4 = inet_ntoa( $from_ip4_packed );
    my $len    = length( $msg );

    $recvc++;
    print("recv: #$recvc from $from_ip4:$from_port len=$len [$msg]\n");

    my @msg = parse_notification_msg_data( $msg );
    #  @msg = ver0  len1  cktype2  ckval3  fr4  seq5  chan6  msg7

    next unless @msg;

    if( $self->{ 'DD' } )
      {
      my $key = "$from_ip4:$msg[4]:$msg[5]:$msg[6]";
      next if exists $self->{ 'DD' }{ $key };
      $self->{ 'DD' }{ $key } = time(); # used by clear_dd_lookup()
      }

    my $cq = $self->{ 'Q' }{ $msg[6] } ||= []; # channel queue

    push @$cq, {
               FROM      => $msg[4],
               FROM_IP4  => $from_ip4,
               FROM_PORT => $from_port,
               CHANNEL   => $msg[6],
               MSG       => $msg[7],
               RTIME     => time(),      # receive time
               };

    $self->{ 'TQMC' }{ '*'     }++;
    $self->{ 'TQMC' }{ $msg[6] }++;

    if( $self->{ 'SSS' } )
      {
      $self->{ 'SSS' }{ '*'     } ||= [];
      $self->{ 'SSS' }{ $msg[6] } ||= [];
      push  @{ $self->{ 'SSS' }{ '*'     } }, time();
      push  @{ $self->{ 'SSS' }{ $msg[6] } }, time();
      shift @{ $self->{ 'SSS' }{ '*'     } } while @{ $self->{ 'SSS' }{ '*'     } } > $self->{ 'SSX' };
      shift @{ $self->{ 'SSS' }{ $msg[6] } } while @{ $self->{ 'SSS' }{ $msg[6] } } > $self->{ 'SSX' };
      }
    }

  return $recvc;
}


sub listen
{
  my $self = shift;

  my $chan = shift;
  my $opt  = shift;

  my $cq = $self->{ 'Q' }{ $chan } ||= []; # channel queue

  my $recvc = $self->__pull_all_available( $chan, $opt );

  my $qc = @$cq;
  print "pulled messages in one pass: $recvc, test qc $qc\n";

  return undef unless @$cq > 0;

  return shift @$cq;
}

sub clear_dd_lookup
{
  my $self = shift;
  my $to   = shift; # timeout cleanup, remove all older than $to seconds

  return unless exists $self->{ 'DD' };

  for my $key ( keys %{ $self->{ 'DD' } } )
    {
    delete $self->{ 'DD' }{ $key } if $self->{ 'DD' }{ $key } < time() - $to;
    }
}

sub stats
{
  my $self = shift;

  my %st;

  # queues stats, seen, currently active (has messages), counts...
  my $qsc = 0;
  while( my ( $k, $v ) = each %{ $self->{ 'Q' } } )
    {
    $qsc++;
    push @{ $st{ 'SEEN_QS' } }, $k;
    my $mc = @{ $v };
    push @{ $st{ 'ACTIVE_QS' } }, $k if $mc > 0;
    $st{ 'QMC' }{ $k } = $mc; # queue message count
    }
  $st{ 'QSC' } = $qsc; # queues count

  # dedup stats
  if( exists $self->{ 'DD' } )
    {
    my $ddc = 0;
    my $ddo = time();
    while( my ( $k, $v ) = each %{ $self->{ 'DD' } } )
      {
      $ddc++;
      $ddo = $v if $v < $ddo;
      }
    $st{ 'DDC' } = $ddc; # dedup lookup count
    $st{ 'DDO' } = $ddo; # dedup oldest lookup
    }

  # speed stats for last SS events
  if( exists $self->{ 'SSS' } )
    {
    while( my ( $k, $v ) = each %{ $self->{ 'SSS' } } )
      {
      $st{ 'SS' }{ $k } = @$v / ( $v->[-1] - $v->[0] ) if @$v > 1 and $v->[-1] - $v->[0] > 0;
      }
    }

  # total queue messages count
  while( my ( $k, $v ) = each %{ $self->{ 'TQMC' } } )
    {
    $st{ 'TQMC' }{ $k } = $v;
    }

  return \%st;
}

1;



=pod

=head1 NAME

Net::BCCN - Broadcast Channel Notifications protocol

=head1 SYNOPSIS

  use Net::BCCN;

  my $bccn = Net::BCCN->new(
    NAME  => "host1/worker/$$",
    ADDR  => '255.255.255.255',
    BIND  => '0.0.0.0',
    PORT  => 1122,
    DD    => 1,         # enable per-message dedup
    SS    => 100,       # track speed stats over last 100 messages
    DEBUG => 0,
  );

  $bccn->open() or die "open failed: " . $bccn->error();

  # publish
  $bccn->notify( 'supply-channel',
                 'txnid=12345:avail=1234:rc=00' );

  # listen on a channel (returns one message, or undef if none waiting)
  while (1)
    {
    my $msg = $bccn->listen( 'work-channel', { TIMEOUT => 1 } );
    next unless $msg;
    process( $msg );
    }

=head1 DESCRIPTION

Net::BCCN implements the BCCN wire protocol - a lightweight
LISTEN/NOTIFY-style notification fabric over UDP broadcast on a
single network segment. Inspired by PostgreSQL's NOTIFY/LISTEN,
but extended across machines and across processes that don't
share a database connection.

Each datagram has the form:

  BCCN1[<len><:<algo>=<sum>>?]<src>:<seq>:<chan>|<payload>

  <len>      decimal byte count of the body after "]"
  <algo>     optional integrity algorithm name (e.g. "hmac")
  <sum>      optional integrity check value
  <src>      sender identifier ("from")
  <seq>      sender's per-process sequence counter
  <chan>     channel name ("to")
  <payload>  opaque application-defined bytes

The current implementation handles plain BCCN1 datagrams (no
integrity check). HMAC and directed-channel addressing are part
of the protocol design but not yet implemented in this module.

Semantics are fire-and-forget. No acks, no persistence, no
replay. Suits notify-fabric use cases where occasional packet
loss is acceptable.

=head1 CONSTRUCTOR

=head2 new( %options )

Creates a new BCCN endpoint. Does not open the socket - call
open() to do that.

Options:

=over 4

=item NAME

The local instance's name string used in outgoing datagrams as source name.
Defaults to "?" (the protocol's unknown-sender placeholder).
A typical convention is C<< host/program/pid >>, e.g.
C<< host4/processor/12345 >>.

=item ADDR

Broadcast destination address. Defaults to C<255.255.255.255>
(limited broadcast - never crosses routers). For directed
subnet broadcast, use the subnet's broadcast address such as
C<10.0.0.255>.

=item BIND

Local bind address. Defaults to C<0.0.0.0> (all interfaces).

=item PORT

UDP port to bind and send on. Required. Sender and listener
must agree on the port number.

=item DD

If true, enable per-message deduplication. The key is the concatenation of
(sender IP, src, seq, chan); duplicates within this key set are
silently dropped. Useful when the application sends each
notification twice for loss reduction. Periodically call
clear_dd_lookup() to expire old entries.

=item SS

If a positive integer N, enable speed statistics tracking over
the last N messages. Per-channel and aggregate rates are
exposed via stats(). If unset, no speed tracking.

=item DEBUG

True value or positive integer to enable debug output.
Currently used for selective trace prints during recv.

=back

=head1 METHODS

=head2 open()

Creates the UDP socket, sets SO_REUSEADDR, SO_BROADCAST, and
non-blocking mode, and binds to BIND:PORT. Returns 1 on
success, undef on failure (call error() for details).

=head2 notify( $chan, $payload )

Builds a BCCN1 datagram with the current NAME as src, the next
sequence number, the given channel and payload, and broadcasts
it. Returns 1 on success, undef on failure (call error()).

The channel name is opaque to the protocol; sender and
receivers agree on its meaning. Any whitespace-free string is valid.

The payload is opaque bytes; format is application's choice.
Keep the whole datagram under 1400 bytes to avoid IP
fragmentation.

=head2 listen( $chan, \%opt )

Pulls all currently available datagrams off the socket into
per-channel queues, then returns one queued message from the
named channel or undef if none is available.

Note that even the sender (caller of notify()) will receive its own
message if calls listen() on the same channel as notify(). BCCN is
just a transport, execution logic is up to the implementation of the
client.

Options:

=over 4

=item TIMEOUT

Seconds to wait for the first datagram if the channel queue is
empty. 0 (default) means non-blocking. Once at least one
datagram has been queued, the method drains everything else
that's immediately readable without further waiting.

=back

Returned messages are hashrefs:

  {
    FROM      => <src>,           # sender identifier from datagram
    FROM_IP4  => <ip address>,    # sender IP from recvfrom()
    FROM_PORT => <udp port>,      # sender port from recvfrom()
    CHANNEL   => <chan>,
    MSG       => <payload>,
    RTIME     => <unix time>,     # receive time
  }

Note: datagrams for other channels read off the socket in the
same pass are queued internally; subsequent listen() calls on
those channels will return them.

The idea for the TIMEOUT is to allow shortest possible sleep between
processing and housekeeping (when no message available and timeout expired).
So calling listen() with timeout will check for incoming messages, and if any,
will read them all and return either requested channel message or undef if none.
When no messages are available it will block until timeout expired or until
any new message arrive (regardless the requested channel or not). On returning
undef, housekeeping or other work can be done.

=head2 error()

Returns the last error message, or undef if the last operation
succeeded. Cleared at the start of each operation that sets it.

=head2 stats()

Returns a hashref of runtime statistics:

  {
    QSC       => <count>,             # total queues/channels count
    SEEN_QS   => [ <chan>, ... ],     # all queues/channels ever seen
    ACTIVE_QS => [ <chan>, ... ],     # queues/channels with queued messages
    QMC       => { <chan> => <count>, ... },   # per-channel queue length

    TQMC      => { '*' => <count>,    # total messages received
                   <chan> => <count>, # per-queue/channel total count
                   ... },

    DDC       => <count>,             # dedup table size  (if DD enabled)
    DDO       => <unix time>,         # oldest dedup entry (unix time)

    SS        => { '*' => <rate>,     # messages per second (if SS enabled)
                   <chan> => <rate>,  # per-queue/channel speed
                   ... },
  }

=head2 clear_dd_lookup( $seconds )

Removes dedup entries older than $seconds. Call periodically
when DD is enabled to prevent unbounded growth of the dedup
table. Has no effect when DD is disabled. call without argument or 0 to
clear the entire table.

=head1 PROTOCOL DETAILS

The wire format is a printable ASCII envelope plus an opaque
payload. The envelope is fixed across protocol versions; only
the body interpretation changes between BCCN1, a hypothetical
BCCN2, etc. Anything an intermediary needs for routing,
authentication, or framing lives in the envelope; everything
else is body.

This module accepts the optional C<:E<lt>algoE<gt>=E<lt>sumE<gt>>
integrity slot in the envelope when parsing (the parser regex
allows it) but does not currently verify or generate it.

Reserved characters:

=over 4

=item *

Space, tab, CR, LF: not allowed in src or chan.

=item *

C<|>: separates body header from payload; first occurrence
marks the boundary.

=item *

C<:>: separates src/seq/chan in the body header; not allowed
inside src or chan.

=item *

C<[ ]>: envelope brackets.

=item *

C<!> as first character of chan: reserved for all-form ("!")
and directed-form ("!<target>") delivery. Not implemented in
this module yet.

=item *

C<?> as exact value of src: reserved unknown-sender placeholder.

=back

=head1 LIMITATIONS

This module implements a minimal BCCN1 baseline. Not yet
supported:

=over 4

=item *

HMAC or other integrity check (envelope syntax recognised but
not verified).

=item *

C<!>-prefix channel forms: all-broadcast and directed delivery.

=item *

Sequence-number-based per-sender dedup (only IP+src+seq+chan
tuple dedup via the DD option).

=item *

Multicast delivery. The current revision is broadcast-only on
a single L2 segment. Multicast is considered for next releases.

=back

=head1 EXAMPLE

A small publisher/subscriber pair:

  # publisher.pl
  use Net::BCCN;
  my $b = Net::BCCN->new( NAME => "tx-source/$$",
                          PORT => 5400 );
  $b->open() or die $b->error();
  my $i = 0;
  while (1)
    {
    $b->notify( 'demo/tick', "i=$i ts=" . time() );
    $i++;
    sleep 1;
    }

  # subscriber.pl
  use Net::BCCN;
  my $b = Net::BCCN->new( NAME => "tx-sink/$$",
                          PORT => 5400,
                          DD   => 1 );
  $b->open() or die $b->error();
  while (1)
    {
    my $msg = $b->listen( 'demo/tick', { TIMEOUT => 1 } );
    next unless $msg;
    print "$msg->{FROM_IP4} $msg->{FROM} -> $msg->{MSG}\n";
    }

Run multiple subscribers on the same host - all of them will
receive every datagram because the underlying socket has
SO_REUSEADDR set.

=head1 SEE ALSO

PostgreSQL LISTEN/NOTIFY - the inspiration for BCCN's semantics.

L<IO::Socket::INET>, L<IO::Select> - the Perl networking
primitives used internally.

=head1 AUTHOR

    Vladi Belperchinov-Shabanski "Cade" <cade@noxrun.com>
    <http://cade.noxrun.com>
    https://github.com/cade-vs/bccn

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Vladi Belperchinov-Shabanski.

This module is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License,
version 2 or, at your option, any later version.

=cut
