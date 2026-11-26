##############################################################################
#
#  Net::Tools::Socket::Pair socketpair high-level API
#  Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
#
#  socketpair_create() / socketpair_send() / socketpair_recv()
#  non-blocking message passing over socketpair( AF_UNIX, SOCK_SEQPACKET )
#  (default) or socketpair( AF_UNIX, SOCK_DGRAM )
#
#  send/recv never sleep, regardless of the blocking mode of the
#  handle (MSG_DONTWAIT is used on every call), never raise SIGPIPE and,
#  given valid arguments, never die (see POD). Result is 1 (ok), 0 (again,
#  too big or error) or undef (EOF), the reason is in $SOCK_ERR, see
#  Net::Tools::Socket::Err.
#
#  one socketpair_send() is exactly one socketpair_recv() on the other side.
#  messages are byte strings; serialize data structures before sending.
#
#    my ( $sock1, $sock2 ) = socketpair_create( $type );
#
#      $type is 'seqpacket' (default) or 'dgram', case insensitive
#      returns two connected handles, or empty list on error ($SOCK_ERR is
#      errno, or SOCK_E_INVAL for unknown $type)
#
#      'dgram' has no EOF on recv: when the peer has closed, recv returns 0
#      (SOCK_E_AGAIN) forever, only send() returns undef (SOCK_E_EOF)
#
#    my $res = socketpair_send( $fh, $data );
#
#      1      message queued for the peer (always the whole message)
#      0      SOCK_E_AGAIN   peer's queue is full, nothing sent, retry when writable
#             SOCK_E_TOOBIG  message larger than $MSG_MAX or than the socket buffer
#             SOCK_E_EMPTY   undef or empty message, nothing sent
#             SOCK_E_INVAL   message is a reference or has wide characters
#             errno          anything else (positive), see $SOCK_ERRSTR
#      undef  SOCK_E_EOF     peer has closed
#
#    my $res = socketpair_recv( $fh, \$data );
#
#      1      one complete message is in $data
#      0      SOCK_E_AGAIN   nothing waiting, retry when readable
#             SOCK_E_TOOBIG  incoming message exceeded $MSG_MAX and was discarded
#             SOCK_E_INVAL   $data is not a scalar reference, nothing read
#             errno          anything else (positive), see $SOCK_ERRSTR
#      undef  SOCK_E_EOF     peer has closed and all queued messages were read
#                            (seqpacket only)
#
#  every call clears $SOCK_ERR and $SOCK_ERRSTR (Net::Tools::Socket::Err) on
#  entry and sets them to the reason when the result is not 1.
#
#  loop logic is: when return value is:
#                     1 -- operation successful, send/recv got message
#                     0 -- no message or temporary error, repeat loop
#                 undef -- EOF or permanent error, close socket
#
##############################################################################
package Net::Tools::Socket::Pair;
use strict;
use Exporter;
use Socket qw( AF_UNIX SOCK_SEQPACKET SOCK_DGRAM PF_UNSPEC SOL_SOCKET SO_TYPE MSG_DONTWAIT MSG_NOSIGNAL );
use Net::Tools::Socket::Err;

our $VERSION = '1.60';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  socketpair_create
                  socketpair_send
                  socketpair_recv
                );

our $MSG_MAX = 128 * 1024;

my %SOCK_TYPES = (
                 'SEQPACKET' => SOCK_SEQPACKET,
                 'SEQ'       => SOCK_SEQPACKET,
                 'DGRAM'     => SOCK_DGRAM,
                 'DG'        => SOCK_DGRAM,
                 );

# MSG_NOSIGNAL flag if the system has it (Linux, BSDs), else 0 and SIGPIPE
# is ignored during send instead (macOS). Socket croaks when an undefined
# macro is used, hence eval. "our" only to allow tests of the fallback
our $MSG_NOSIGNAL = eval { MSG_NOSIGNAL() } || 0;

##############################################################################

sub socketpair_create
{
  my $type = uc( shift() || 'SEQPACKET' );

  sock_err_clear();
  my $st = $SOCK_TYPES{ $type } or do { sock_err( SOCK_E_INVAL ); return () };
  socketpair( my $sock1, my $sock2, AF_UNIX, $st, PF_UNSPEC ) or do { sock_err_sys(); return () }; # errno
  return ( $sock1, $sock2 );
}

# returns SOCK_SEQPACKET, SOCK_DGRAM, etc. of a socket handle, -1 if unknown
sub __sock_type
{
  my $fh = shift;
  my $t  = getsockopt( $fh, SOL_SOCKET, SO_TYPE );
  return defined $t ? unpack( 'i', $t ) : -1;
}

sub socketpair_send
{
  my $fh   = shift;
  my $data = shift;

  sock_err_clear();

  return sock_err( SOCK_E_EMPTY,  0 ) unless defined $data and length( $data ) > 0;
  return sock_err( SOCK_E_INVAL,  0 ) if ref( $data ) or ! utf8::downgrade( $data, 1 );
  return sock_err( SOCK_E_TOOBIG, 0 ) if length( $data ) > $MSG_MAX;

  # no SIGPIPE when the peer has closed: MSG_NOSIGNAL, or else SIGPIPE is
  # ignored only during this call, send() then fails with EPIPE (EOF below)
  local $SIG{ 'PIPE' } = 'IGNORE' unless $MSG_NOSIGNAL;

  while( 1 )
    {
    my $n = send( $fh, $data, MSG_DONTWAIT | $MSG_NOSIGNAL );
    return 1          if defined $n;
    next              if $!{ EINTR };
    return sock_err( SOCK_E_AGAIN,  0 ) if $!{ EAGAIN } or $!{ EWOULDBLOCK };
    # seqpacket: ECONNRESET, then EPIPE; dgram: ECONNREFUSED, then ENOTCONN
    return sock_err( SOCK_E_EOF       ) if $!{ EPIPE } or $!{ ECONNRESET } or $!{ ENOTCONN } or $!{ ECONNREFUSED };
    return sock_err( SOCK_E_TOOBIG, 0 ) if $!{ EMSGSIZE };
    return sock_err_sys( 0 ); # errno
    }
}

sub socketpair_recv
{
  my $fh   = shift;
  my $data = shift;

  sock_err_clear();

  return sock_err( SOCK_E_INVAL, 0 ) unless ref( $data ) eq 'SCALAR';

  while( 1 )
    {
    # receive directly into the caller's scalar, its buffer is reused by the
    # next call, no new $MSG_MAX buffer and no copy per message.
    # "$$data = undef" below keeps the allocated buffer, only marks it undef
    my $r = recv( $fh, $$data, $MSG_MAX + 1, MSG_DONTWAIT );
    if( defined $r )
      {
      my $len = length( $$data );
      return 1 if $len > 0 and $len <= $MSG_MAX;
      $$data = undef;
      if( $len == 0 )
        {
        # dgram has no EOF, empty read is an empty datagram, which is never
        # sent by socketpair_send(), skip it. type is checked only here
        next if __sock_type( $fh ) == SOCK_DGRAM;
        return sock_err( SOCK_E_EOF );
        }
      return sock_err( SOCK_E_TOOBIG, 0 );
      }
    $$data = undef;
    next              if $!{ EINTR };
    return sock_err( SOCK_E_AGAIN, 0 ) if $!{ EAGAIN } or $!{ EWOULDBLOCK };
    return sock_err( SOCK_E_EOF      ) if $!{ ECONNRESET };
    return sock_err_sys( 0 ); # errno
    }
}

##############################################################################
1;


=pod

=head1 NAME

Net::Tools::Socket::Pair - non-blocking message passing over socketpair()

=head1 SYNOPSIS

  use Net::Tools::Socket::Pair;
  use Net::Tools::Socket::Err; # only if error details are needed

  my ( $parent_sock, $child_sock ) = socketpair_create()
      or die "socketpair: $SOCK_ERRSTR\n";

  # sender
  my $res = socketpair_send( $parent_sock, $message_bytes );
  # retry later if $SOCK_ERR == SOCK_E_AGAIN

  # receiver, read all pending messages
  my $data;
  while( socketpair_recv( $child_sock, \$data ) )
    {
    # one complete message is in $data
    }
  # peer closed if $SOCK_ERR == SOCK_E_EOF

=head1 DESCRIPTION

Message passing over C<socketpair( AF_UNIX, SOCK_SEQPACKET )> or
C<socketpair( AF_UNIX, SOCK_DGRAM )>, see L</SOCKET TYPES>. Each
C<socketpair_send()> is received by exactly one C<socketpair_recv()> on the
other side, always as a whole message. Messages are byte strings, data
structures must be serialized before sending.

C<socketpair_send()> and C<socketpair_recv()> never sleep, regardless of
the blocking mode of the handle (C<MSG_DONTWAIT> is used on every call), and
never raise C<SIGPIPE> (C<MSG_NOSIGNAL> is used, where the system does not
have it, SIGPIPE is ignored only for the time of the send() call, the
caller's C<$SIG{ 'PIPE' }> is restored). They return:

  1      one whole message sent or received successfully
  0      nothing to read or peer's queue is full (SOCK_E_AGAIN), message
         too big (SOCK_E_TOOBIG), invalid message or system error
         those are considered temporary and operation should be repeated
  undef  peer closed (SOCK_E_EOF), for recv after all queued messages
         were read, socket must be closed

So the result is true only for a message, false for "nothing now", and
undef when the peer is gone, which allows:

  while( socketpair_recv( $fh, \$data ) ) { ... }       # read all pending
  if( ! defined socketpair_recv( $fh, \$data ) ) { ... } # peer closed

The reason for 0 or undef is in C<$SOCK_ERR>, see L</ERRORS>.

C<socketpair_recv()> sets C<$data> to undef whenever the result is not 1,
so a stale value is never left there.

Empty or undef messages are not sent, C<socketpair_send()> returns 0 with
C<SOCK_E_EMPTY>, because the peer would read an empty message as end of
file.

Maximum message size is C<$Net::Tools::Socket::Pair::MSG_MAX> (128 KiB by
default).

All functions are exported by default.

=head1 SOCKET TYPES

  my ( $s1, $s2 ) = socketpair_create();            # SOCK_SEQPACKET
  my ( $s1, $s2 ) = socketpair_create( 'dgram' );   # SOCK_DGRAM

The type is 'seqpacket' (the default) or 'dgram', case insensitive. An
unknown type returns an empty list with C<SOCK_E_INVAL>.

Both keep message boundaries, never drop messages (a full queue returns
C<SOCK_E_AGAIN> to the sender) and hold about the same count of messages.
They differ only when the peer closes:

  seqpacket  recv returns undef (SOCK_E_EOF) after all queued messages are
             read, poll() reports POLLHUP, send returns undef (SOCK_E_EOF)

  dgram      recv never returns EOF, it returns 0 (SOCK_E_AGAIN) forever,
             poll() reports nothing, only send returns undef (SOCK_E_EOF)

So with 'dgram' a receiver which never sends must find out that its peer
is gone in another way (getppid(), waitpid(), etc.). On the other hand,
a 'dgram' handle may be shared by many processes writing to one reader,
which never sees EOF while any of them is still writing.

=head1 ERRORS

All functions clear C<$SOCK_ERR> and C<$SOCK_ERRSTR> on entry and set them
when the result is not 1:

  SOCK_E_AGAIN    nothing to read, or peer's queue is full
  SOCK_E_EOF      peer closed
  SOCK_E_TOOBIG   message over $MSG_MAX or the socket buffer, an incoming
                  message over $MSG_MAX is read and discarded
  SOCK_E_EMPTY    empty or undef message, not sent
  SOCK_E_INVAL    send: message is a reference or has wide (over 255)
                  characters, encode it first
                  recv: $data is not a scalar reference
  errno           any other system error, the positive errno value,
                  its text is in $SOCK_ERRSTR

C<socketpair_create()> sets errno on failure, C<SOCK_E_INVAL> for an
unknown socket type.

errno values are always positive, SOCK_E_* codes are negative, so they never
collide. C<sock_err_name()> returns 'EBADF', etc. for errno values.

They are exported by L<Net::Tools::Socket::Err>, which must be used by the
caller to read them. The error state describes the last call only.

=head1 NOTES

=over 4

=item *

Both functions must be given a socket handle, undef or a value that is not
a handle will die (a closed handle returns 0 with errno). C<socketpair_recv()> must be given a reference to a
writable scalar (C<\$data>) for the received data: anything that is not a
scalar reference returns 0 with C<SOCK_E_INVAL> and the message stays
queued, a reference to a read-only value (C<\'text'>) will die.

=item *

Tested on Linux only. C<SOCK_SEQPACKET> on C<AF_UNIX> sockets is not
supported on macOS, use 'dgram' there, but the system may limit 'dgram'
messages far below C<$MSG_MAX> (net.local.dgram.maxdgram). Where
C<MSG_NOSIGNAL> is not available (macOS), C<SIGPIPE> is ignored during
send instead, see above.

=back

=head1 SEE ALSO

L<Net::Tools::Socket>, L<Net::Tools::Socket::Err>, L<socketpair(2)>, L<Socket>

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com>
  http://cade.noxrun.com/

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=cut
