##############################################################################
#
#  Net::Tools::Socket perl module
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
package Net::Tools::Socket;
use strict;
use Exporter;
use Time::HiRes qw( time );
use Net::Tools::Socket::Err;

our $VERSION = '1.60';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  socket_read
                  socket_write
                  socket_print

                  socket_read_message
                  socket_write_message

                  socket_can_write
                  socket_can_read
                );

our %EXPORT_TAGS = (
                   'all'  => \@EXPORT,
                   'none' => [],
                   );

# socket_write_message() sends messages up to this size (length + data) with a
# single write, bigger ones with two writes, so their data is not copied
our $WRITE_MESSAGE_JOIN_MAX = 64 * 1024;

##############################################################################

sub socket_read
{
   my $sock    = shift;
   my $data    = shift;
   my $readlen = shift;
   my $timeout = shift; # seconds, fractions allowed, undef waits forever, 0 does not wait

   sock_err_clear();
   my $stime = time();
   $$data = undef;

   my $rlen = $readlen;
   while( $rlen > 0 )
     {
     return undef unless socket_can_read( $sock, $timeout );
     # by design $timeout limits each wait for the socket and the total is checked
     # only after it, so one call may take up to about twice $timeout
     return sock_err( SOCK_E_TIMEOUT, undef ) if $timeout > 0 and time() - $stime > $timeout;

     my $part;
     my $plen = $sock->sysread( $part, $rlen );
     next if ! defined $plen and $!{ EINTR }; # interrupted by signal, retry within timeout

     return sock_err( SOCK_E_EOF, undef ) if defined $plen and $plen == 0;
     return $!{ ECONNRESET } ? sock_err( SOCK_E_EOF, undef ) : sock_err_sys( undef ) unless $plen > 0;

     $$data .= $part;
     $rlen -= $plen;
#print STDERR "SOCKET_READ: part [$part] [$plen] [$rlen]\n";
     }

#print STDERR "SOCKET_READ: incoming data [$$data]\n";

  return $readlen - $rlen;
}

sub socket_write
{
   my $sock     = shift;
   my $data     = shift;
   my $writelen = shift;
   my $timeout  = shift; # seconds, fractions allowed, undef waits forever, 0 does not wait

   sock_err_clear();
   # cannot write more than given, wide (over 255) characters cannot be written as bytes
   return sock_err( SOCK_E_INVAL, undef ) if $writelen > length( $data ) or ! utf8::downgrade( $data, 1 );
   my $stime = time();

#print STDERR "SOCKET_WRITE: outgoing data [$data]\n";
   my $wpos = 0;
   while( $wpos < $writelen )
     {
     return undef unless socket_can_write( $sock, $timeout );
     # by design $timeout limits each wait for the socket and the total is checked
     # only after it, so one call may take up to about twice $timeout
     return sock_err( SOCK_E_TIMEOUT, undef ) if $timeout > 0 and time() - $stime > $timeout;

     # WARNING! closed peer raises SIGPIPE, caller must ignore it, see POD
     my $plen = $sock->syswrite( $data, $writelen - $wpos, $wpos );
     next if ! defined $plen and $!{ EINTR }; # interrupted by signal, retry within timeout
#print STDERR "SOCKET_WRITE: part [$plen]\n";

     return $!{ EPIPE } || $!{ ECONNRESET } ? sock_err( SOCK_E_EOF, undef ) : sock_err_sys( undef ) unless $plen > 0;

     $wpos += $plen;
     }

#print STDERR "SOCKET_WRITE: part [$wpos] == writelen [$writelen]\n";
  return $wpos;
}

sub socket_print
{
   my $sock     = shift;
   my $data     = shift;
   my $timeout  = shift; # seconds, fractions allowed, undef waits forever, 0 does not wait

   return socket_write( $sock, $data, length( $data ), $timeout );
}

##############################################################################

# returns read data, "" if incoming length is 0, i.e. empty data, or undef on
# error with $SOCK_ERR set: SOCK_E_EOF, SOCK_E_TIMEOUT, SOCK_E_TOOBIG or errno
# (EBADF, etc.). on any error after the first byte of the length was read the
# stream is out of sync, the caller must close the socket

sub socket_read_message
{
  my $sock    = shift;
  my $timeout = shift; # seconds, fractions allowed, undef waits forever, 0 does not wait
  my $maxlen  = shift;

  sock_err_clear();

  $maxlen = 0xFFFFFFFF if $maxlen <= 0 or $maxlen > 0xFFFFFFFF;

  # socket_read() clears and sets $SOCK_ERR
  my $data_len_N32;
  socket_read( $sock, \$data_len_N32, 4, $timeout ) // return undef;

  my $data_len = unpack( 'N', $data_len_N32 );
  return sock_err( SOCK_E_TOOBIG ) if $data_len > $maxlen;
  return '' if $data_len == 0;

  my $read_data;
  socket_read( $sock, \$read_data, $data_len, $timeout ) // return undef;

  return $read_data;
}

sub socket_write_message
{
  my $sock    = shift;
  my $data    = shift;
  my $timeout = shift; # seconds, fractions allowed, undef waits forever, 0 does not wait

  sock_err_clear();

  return sock_err( SOCK_E_INVAL, undef ) if ! utf8::downgrade( $data, 1 );

  my $data_len = length( $data );
  return sock_err( SOCK_E_TOOBIG, undef ) if $data_len > 0xFFFFFFFF; # 32bit length field would wrap

  if( 4 + $data_len <= $WRITE_MESSAGE_JOIN_MAX )
    {
    # small message, length and data in one write. a separate small length
    # write stalls on TCP for ~40ms per message (Nagle + delayed ACK)
    socket_write( $sock, pack( 'N', $data_len ) . $data, 4 + $data_len, $timeout ) // return undef;
    return 1;
    }

  # big message, two writes, so $data is not copied
  socket_write( $sock, pack( 'N', $data_len ), 4, $timeout ) // return undef;
  socket_write( $sock, $data, $data_len, $timeout ) // return undef;

  return 1;
}

##############################################################################

sub socket_can_write
{
  my $sock    = shift;
  my $timeout = shift; # seconds, fractions allowed, undef waits forever, 0 does not wait

  sock_err_clear();
  my $win;
  my $fdno = fileno( $sock );
  return undef unless defined $fdno and $fdno >= 0;
  vec( $win, $fdno, 1 ) = 1;
  return __socket_select( undef, $win, $timeout );
}

sub socket_can_read
{
  my $sock    = shift;
  my $timeout = shift; # seconds, fractions allowed, undef waits forever, 0 does not wait

  sock_err_clear();
  my $rin;
  my $fdno = fileno( $sock );
  return undef unless defined $fdno and $fdno >= 0;
  vec( $rin, $fdno, 1 ) = 1;
  return __socket_select( $rin, undef, $timeout );
}

# select() on one read or write bit vector, restarted on EINTR with the
# remaining time. returns 1 if ready, 0 on timeout (SOCK_E_TIMEOUT) or undef
# on error ($SOCK_ERR is errno). undef $timeout waits forever, 0 does not
# wait, select() only checks once
sub __socket_select
{
  my $rin     = shift;
  my $win     = shift;
  my $timeout = shift; # seconds, fractions allowed, undef waits forever, 0 does not wait

  my $etime = defined $timeout ? time() + $timeout : undef;
  while( 4 )
    {
    my $left;
    if( defined $etime )
      {
      $left = $etime - time();
      $left = 0 if $left < 0;
      }
    # sets are not modified when select() fails (EINTR), so restart can reuse them
    my $n = select( $rin, $win, undef, $left );
    return 1 if $n > 0;
    return sock_err( SOCK_E_TIMEOUT, 0 ) if $n == 0;
    next if $!{ EINTR };
    return sock_err_sys( undef );
    }
}

##############################################################################

=pod


=head1 NAME

Net::Tools::Socket - set of socket I/O functions

=head1 SYNOPSIS

  use Net::Tools::Socket qw( :all );  # import all functions
  use Net::Tools::Socket;             # the same as :all :)
  use Net::Tools::Socket qw( :none ); # do not import anything, use full package names

  # --------------------------------------------------------------------------

  my $read_res_len  = socket_read(  $socket, $data_ref, $length, $timeout );
  my $write_res_len = socket_write( $socket, $data,     $length, $timeout );
  my $write_res_len = socket_print( $socket, $data, $timeout );

  # --------------------------------------------------------------------------

  my $read_data = socket_read_message(  $socket, $timeout, $maxlen );
  my $write_res = socket_write_message( $socket, $data, $timeout );

  # --------------------------------------------------------------------------

  # error details, see ERRORS
  use Net::Tools::Socket::Err;
  print "error: $SOCK_ERRSTR\n" unless defined $read_data;

  # --------------------------------------------------------------------------

=head1 FUNCTIONS

=head2 socket_read(  $socket, $data_ref, $length, $timeout )

Reads $length sized data from the $socket and stores it to $data_ref scalar
reference.

Returns read length, which is always the requested $length, or undef on
timeout, end of file or error, see L</ERRORS>. On undef, $data_ref may hold
the partially read data.

$timeout is optional, it is in seconds and can be less than 1 second.
If $timeout is undef (not given) it waits forever, if it is 0 it does not
wait at all, only checks once if the socket is ready.

$timeout limits each wait for the socket to become ready, the total time
is checked only after each wait, so one call may take up to about twice
$timeout when the data arrives slowly in parts.

=head2 socket_write( $socket, $data,     $length, $timeout )

Writes $length sized data from $data scalar to the $socket. If $length is
larger than the length of $data, or $data contains wide (over 255) characters (encode it
first), nothing is written and undef is returned with SOCK_E_INVAL.

Returns write length, which is always the requested $length, or undef on
timeout, closed peer or error, see L</ERRORS>. On undef, part of the data may
already be sent.

WARNING! Writing to a socket closed by the peer raises SIGPIPE, which kills
the process by default. This module does not touch signals, handling them
is the caller's responsibility. Set, once at program start:

  $SIG{ 'PIPE' } = 'IGNORE';

then such writes fail with $SOCK_ERR set to SOCK_E_EOF instead.

$timeout is optional, it is in seconds and can be less than 1 second.
If $timeout is undef (not given) it waits forever, if it is 0 it does not
wait at all, only checks once if the socket is ready.

$timeout limits each wait for the socket to become writable, the total time
is checked only after each wait, so one call may take up to about twice
$timeout when the peer reads slowly.

=head2 socket_print( $socket, $data, $timeout )

Same as socket_write() but calculates requested length from the $data scalar.

WARNING! SIGPIPE on closed peer, see socket_write().

$timeout is optional, it is in seconds and can be less than 1 second.
If $timeout is undef (not given) it waits forever, if it is 0 it does not
wait at all, only checks once if the socket is ready.

See socket_write() for how $timeout is applied.

=head2 socket_read_message(  $socket, $timeout, $maxlen )

Reads 32bit network-order integer, which then is used as data size to be read
from the socket (i.e. message = 32bit-integer + data ).

Returns the read data, "" for an empty message, or undef on error with
$SOCK_ERR set (see L</ERRORS>):

  SOCK_E_EOF       peer closed, also in the middle of a message
  SOCK_E_TIMEOUT   $timeout expired
  SOCK_E_TOOBIG    message length is over $maxlen
  errno            system call failed (EBADF, etc.)

For a closed handle, or one without a real file descriptor, it returns
undef and $SOCK_ERR is not set, see socket_can_read().

On any error after the first byte of the length was read (a timeout, EOF or
system error in the middle of the 4 length bytes, SOCK_E_TOOBIG, or an
error while reading the message data), the rest of the message is left
unread, so the socket stream is out of sync and cannot be used anymore:
the caller must close the socket and reconnect. With $timeout 0 this happens
whenever the message has not fully arrived yet.

$timeout is optional, it is in seconds and can be less than 1 second.
If $timeout is undef (not given) it waits forever, if it is 0 it does not
wait at all, only checks once if the socket is ready.

$timeout limits each of the two socket_read() calls (length and data)
separately, see socket_read() for how $timeout is applied.

$maxlen is optional, if it is not given, 0 or negative, the default is used.
The default and the maximum are 2**32-1 (0xFFFFFFFF).

=head2 socket_write_message( $socket, $data, $timeout )

Writes 32bit network-order integer, which is the size of the given $data to be
written to the $socket and then writes the data
(i.e. message = 32bit-integer + data ).

Messages up to $Net::Tools::Socket::WRITE_MESSAGE_JOIN_MAX bytes (length +
data, 64 KiB by default) are sent with one socket_write() call. Bigger ones
are sent with two socket_write() calls (the length and the data), so a big
$data is not copied. A separate small write of the length would stall every
small message on TCP for about 40 ms (Nagle algorithm and delayed ACK).

NOTE: messages longer than $WRITE_MESSAGE_JOIN_MAX are split into two
socket_write() calls, the 4 bytes length is written alone first. On TCP
without TCP_NODELAY, each such message may still stall once for about 40 ms.
This is small compared to the time to send that much data, but if many long
messages are exchanged, set TCP_NODELAY on the socket:

  use Socket qw( IPPROTO_TCP TCP_NODELAY );
  setsockopt( $socket, IPPROTO_TCP, TCP_NODELAY, 1 );

or raise $Net::Tools::Socket::WRITE_MESSAGE_JOIN_MAX, at the cost of
copying the data of each message up to that size.

On any error after the first byte was written (a timeout, closed peer or
system error in the middle of the length or of the data), only part of the
message is sent, so the socket stream is out of sync and cannot be used
anymore: the caller must close the socket and reconnect. With $timeout 0
this happens whenever the peer does not read fast enough.

Returns 1 on success or undef for message or network error, see L</ERRORS>.
$data must not contain wide (over 255) characters, encode it first,
otherwise undef is returned with SOCK_E_INVAL. An empty or undef $data is
sent as an empty message, which socket_read_message() returns as "".
$data larger than 4 GiB - 1 (2**32 - 1) bytes does not fit the 32bit length,
nothing is written and undef is returned with SOCK_E_TOOBIG.

WARNING! SIGPIPE on closed peer, see socket_write().

$timeout is optional, it is in seconds and can be less than 1 second.
If $timeout is undef (not given) it waits forever, if it is 0 it does not
wait at all, only checks once if the socket is ready.

$timeout limits each socket_write() call separately (one or two, see above),
see socket_write() for how $timeout is applied.

=head2 socket_can_read( $socket, $timeout ) / socket_can_write( $socket, $timeout )

Return 1 if the $socket is ready for reading/writing within $timeout, 0 on
timeout ($SOCK_ERR is SOCK_E_TIMEOUT), undef on error ($SOCK_ERR is errno).

If the $socket is closed or has no real file descriptor (fileno() is undef
or -1, for example an in-memory handle), they return undef at once and
$SOCK_ERR is not set, since such a handle cannot be read from or written to.

$timeout is in seconds and can be less than 1 second. If $timeout is undef
(not given) it waits forever, if it is 0 it does not wait at all, only
checks once if the socket is ready.

=head1 ERRORS

All functions clear $SOCK_ERR and $SOCK_ERRSTR on entry and set them on
failure, except for a closed handle, see socket_can_read(). $SOCK_ERR is a
negative SOCK_E_* code, or the positive errno value if a system call failed
(except EPIPE and ECONNRESET, which are reported as SOCK_E_EOF), and
$SOCK_ERRSTR is its text:

  SOCK_E_EOF       peer closed (also EPIPE and ECONNRESET)
  SOCK_E_TIMEOUT   $timeout expired
  SOCK_E_TOOBIG    message over $maxlen, or $data over 2**32-1 bytes
  SOCK_E_INVAL     $length larger than $data, or wide characters in $data
  errno            any other system error, the positive errno value,
                   its text is in $SOCK_ERRSTR

$SOCK_ERR and $SOCK_ERRSTR are exported by L<Net::Tools::Socket::Err>,
which must be used by the caller to read them:

  use Net::Tools::Socket::Err;

  my $data = socket_read_message( $socket, $timeout );
  print "error: $SOCK_ERRSTR\n" if $SOCK_ERR;

The error state describes the last call only, read it right after the call.

=head1 TODO

  * more docs

=head1 REQUIRED MODULES

Net::Tools::Socket uses:

  * Time::HiRes
  * Net::Tools::Socket::Err

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-net-tools.git

  git clone https://github.com/cade-vs/perl-net-tools.git

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=cut

##############################################################################
1;
###EOF########################################################################

