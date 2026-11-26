#!/usr/bin/perl
##############################################################################
#
#  Net::Tools test suite -- Net::Tools::Socket::Pair
#  Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
use strict;
use lib 'lib', '../lib';
use Test::More;
use Net::Tools::Socket::Pair;
use Net::Tools::Socket::Err;

plan( skip_all => 'Net::Tools::Socket::Pair needs Linux (SOCK_SEQPACKET, MSG_NOSIGNAL)' ) unless $^O eq 'linux';

my ( $A, $B ) = socketpair_create();
ok( $A && $B, 'socketpair_create() returns two handles' ) or BAIL_OUT( "socketpair_create: $SOCK_ERRSTR" );
is( $SOCK_ERR, undef, 'socketpair_create() leaves no error' );

my $MAX = $Net::Tools::Socket::Pair::MSG_MAX;
my $data;

##############################################################################
# basic send and receive
##############################################################################

is( socketpair_send( $A, 'hello' ), 1, 'socketpair_send() returns 1' );
is( $SOCK_ERR, undef, 'socketpair_send() leaves no error' );
is( socketpair_recv( $B, \$data ), 1, 'socketpair_recv() returns 1' );
is( $data, 'hello', 'socketpair_recv() message' );
is( $SOCK_ERR, undef, 'socketpair_recv() leaves no error' );

# message boundaries are kept, one send is one recv
socketpair_send( $A, $_ ) for qw( one two three );
my @got;
push @got, $data while socketpair_recv( $B, \$data );
is_deeply( \@got, [ qw( one two three ) ], 'one send is exactly one recv' );
is( $SOCK_ERR, SOCK_E_AGAIN, 'queue drained gives SOCK_E_AGAIN' );

# binary clean
my $raw = join '', map { chr } 0 .. 255;
socketpair_send( $A, $raw );
socketpair_recv( $B, \$data );
is( $data, $raw, 'binary clean' );

# exactly $MSG_MAX
is( socketpair_send( $A, 'm' x $MAX ), 1, 'message of exactly $MSG_MAX is sent' );
is( socketpair_recv( $B, \$data ), 1, 'message of exactly $MSG_MAX is received' );
is( length( $data ), $MAX, 'message of exactly $MSG_MAX length' );

##############################################################################
# the caller's scalar is reused as the receive buffer
##############################################################################

# a big message first, then a small one into the same scalar
socketpair_send( $A, 'b' x 1000 );
socketpair_recv( $B, \$data );
socketpair_send( $A, 'small' );
is( socketpair_recv( $B, \$data ), 1, 'small message after a big one' );
is( $data, 'small', 'small message is not mixed with the previous big one' );

# a scalar that held a wide character string gets plain bytes
my $wide = "\x{100}\x{101}";
socketpair_send( $A, "\xe9" );
is( socketpair_recv( $B, \$wide ), 1, 'recv into a scalar that held a wide string' );
is( $wide, "\xe9", 'received bytes, not the old wide string' );
ok( ! utf8::is_utf8( $wide ), 'received data has no UTF8 flag' );

# a hash element and an array element are scalars too
my %h;
socketpair_send( $A, 'into hash' );
is( socketpair_recv( $B, \$h{ 'x' } ), 1, 'recv into a hash element' );
is( $h{ 'x' }, 'into hash', 'hash element message' );

##############################################################################
# nothing waiting: 0, SOCK_E_AGAIN, $data is undef
##############################################################################

$data = 'stale';
is( socketpair_recv( $B, \$data ), 0, 'socketpair_recv() with nothing waiting returns 0' );
is( $SOCK_ERR, SOCK_E_AGAIN, 'nothing waiting sets SOCK_E_AGAIN' );
is( $data, undef, 'nothing waiting leaves $data undef, not the old value' );

##############################################################################
# send argument checking
##############################################################################

is( socketpair_send( $A, '' ), 0, 'empty message is not sent' );
is( $SOCK_ERR, SOCK_E_EMPTY, 'empty message sets SOCK_E_EMPTY' );
is( socketpair_send( $A, undef ), 0, 'undef message is not sent' );
is( $SOCK_ERR, SOCK_E_EMPTY, 'undef message sets SOCK_E_EMPTY' );
is( socketpair_send( $A, "\x{100}" ), 0, 'wide character message is not sent' );
is( $SOCK_ERR, SOCK_E_INVAL, 'wide character message sets SOCK_E_INVAL' );
is( socketpair_send( $A, 'x' x ( $MAX + 1 ) ), 0, 'message over $MSG_MAX is not sent' );
is( $SOCK_ERR, SOCK_E_TOOBIG, 'message over $MSG_MAX sets SOCK_E_TOOBIG' );
for my $ref ( \'text', [ 1 ], { a => 1 } )
  {
  is( socketpair_send( $A, $ref ), 0, 'reference message ' . ref( $ref ) . ' is not sent' );
  is( $SOCK_ERR, SOCK_E_INVAL, 'reference message ' . ref( $ref ) . ' sets SOCK_E_INVAL' );
  }

# a wide character string that fits in bytes is sent as bytes
my $latin = "\xe9";
utf8::upgrade( $latin );
is( socketpair_send( $A, $latin ), 1, 'upgraded latin-1 string is sent' );
socketpair_recv( $B, \$data );
is( $data, "\xe9", 'upgraded latin-1 string arrives as one byte' );

# nothing of the refused messages reached the peer
is( socketpair_recv( $B, \$data ), 0, 'refused messages were not sent' );

##############################################################################
# recv argument checking
##############################################################################

my $plain;
is( socketpair_recv( $B, $plain ), 0, 'undef plain scalar instead of a reference returns 0' );
is( $SOCK_ERR, SOCK_E_INVAL, 'undef plain scalar sets SOCK_E_INVAL' );
is( $plain, undef, 'undef plain scalar is not autovivified' );
is( socketpair_recv( $B, 'text' ), 0, 'plain string instead of a reference returns 0' );
is( socketpair_recv( $B, [] ), 0, 'array reference returns 0' );
is( $SOCK_ERR, SOCK_E_INVAL, 'array reference sets SOCK_E_INVAL' );

socketpair_send( $A, 'kept' );
socketpair_recv( $B, $plain );
is( socketpair_recv( $B, \$data ), 1, 'a refused recv does not consume the message' );
is( $data, 'kept', 'message is still there after a refused recv' );

##############################################################################
# incoming message over $MSG_MAX is discarded
##############################################################################

{
  local $Net::Tools::Socket::Pair::MSG_MAX = 100_000;
  is( socketpair_send( $A, 'z' x 100_000 ), 1, 'sender with a bigger $MSG_MAX' );
}
{
  local $Net::Tools::Socket::Pair::MSG_MAX = 1000;
  $data = 'stale';
  is( socketpair_recv( $B, \$data ), 0, 'incoming message over $MSG_MAX returns 0' );
  is( $SOCK_ERR, SOCK_E_TOOBIG, 'incoming message over $MSG_MAX sets SOCK_E_TOOBIG' );
  is( $data, undef, 'oversized message leaves $data undef' );
}
socketpair_send( $A, 'after big' );
is( socketpair_recv( $B, \$data ), 1, 'next message after a discarded one' );
is( $data, 'after big', 'oversized message was discarded whole' );

##############################################################################
# peer's queue full: 0, SOCK_E_AGAIN
##############################################################################

my ( $C, $D ) = socketpair_create();
my $sent = 0;
$sent++ while socketpair_send( $C, 'q' x 1000 );
ok( $sent > 0, "queue filled after $sent messages" );
is( $SOCK_ERR, SOCK_E_AGAIN, 'full queue sets SOCK_E_AGAIN' );
my $read = 0;
$read++ while socketpair_recv( $D, \$data );
is( $read, $sent, 'every queued message is received' );

##############################################################################
# peer closed: undef, SOCK_E_EOF
##############################################################################

socketpair_send( $C, 'last words' );
close( $C );
is( socketpair_recv( $D, \$data ), 1, 'queued message is still read after the peer closed' );
is( $data, 'last words', 'queued message after close' );
$data = 'stale';
is( socketpair_recv( $D, \$data ), undef, 'socketpair_recv() returns undef when the peer closed' );
is( $SOCK_ERR, SOCK_E_EOF, 'peer closed sets SOCK_E_EOF on recv' );
is( $data, undef, 'peer closed leaves $data undef' );

is( socketpair_send( $D, 'nobody' ), undef, 'socketpair_send() returns undef when the peer closed' );
is( $SOCK_ERR, SOCK_E_EOF, 'peer closed sets SOCK_E_EOF on send' );

# own handle closed: 0 and errno
$data = 'stale';
is( socketpair_recv( $C, \$data ), 0, 'recv on a closed handle returns 0' );
ok( $SOCK_ERR > 0, 'recv on a closed handle sets errno (' . sock_err_name() . ')' );
is( $data, undef, 'recv on a closed handle leaves $data undef' );
is( socketpair_send( $C, 'x' ), 0, 'send on a closed handle returns 0' );
ok( $SOCK_ERR > 0, 'send on a closed handle sets errno (' . sock_err_name() . ')' );
close( $D );

close( $A );
close( $B );

##############################################################################
# socket types
##############################################################################

use Socket qw( SOL_SOCKET SO_TYPE SOCK_SEQPACKET SOCK_DGRAM );
sub sock_type { unpack( 'i', getsockopt( shift(), SOL_SOCKET, SO_TYPE ) ) }

my ( $S1, $S2 ) = socketpair_create();
is( sock_type( $S1 ), SOCK_SEQPACKET, 'default type is SOCK_SEQPACKET' );
( $S1, $S2 ) = socketpair_create( 'SeqPacket' );
is( sock_type( $S1 ), SOCK_SEQPACKET, "'SeqPacket' is SOCK_SEQPACKET (case insensitive)" );
( $S1, $S2 ) = socketpair_create( 'dgram' );
is( sock_type( $S1 ), SOCK_DGRAM, "'dgram' is SOCK_DGRAM" );
is( sock_type( $S2 ), SOCK_DGRAM, "'dgram' both ends are SOCK_DGRAM" );

my @bad = socketpair_create( 'stream' );
is( scalar( @bad ), 0, 'unknown type returns empty list' );
is( $SOCK_ERR, SOCK_E_INVAL, 'unknown type sets SOCK_E_INVAL' );

##############################################################################
# dgram: same messages as seqpacket
##############################################################################

my ( $E, $F ) = socketpair_create( 'dgram' );

is( socketpair_send( $E, 'hello' ), 1, 'dgram: send returns 1' );
is( socketpair_recv( $F, \$data ), 1, 'dgram: recv returns 1' );
is( $data, 'hello', 'dgram: message' );

is( socketpair_send( $F, 'back' ), 1, 'dgram: send the other way' );
is( socketpair_recv( $E, \$data ), 1, 'dgram: recv the other way' );
is( $data, 'back', 'dgram: message the other way' );

socketpair_send( $E, $_ ) for qw( one two three );
@got = ();
push @got, $data while socketpair_recv( $F, \$data );
is_deeply( \@got, [ qw( one two three ) ], 'dgram: one send is exactly one recv' );
is( $SOCK_ERR, SOCK_E_AGAIN, 'dgram: queue drained gives SOCK_E_AGAIN' );

socketpair_send( $E, $raw );
socketpair_recv( $F, \$data );
is( $data, $raw, 'dgram: binary clean' );

is( socketpair_send( $E, 'm' x $MAX ), 1, 'dgram: message of exactly $MSG_MAX is sent' );
is( socketpair_recv( $F, \$data ), 1, 'dgram: message of exactly $MSG_MAX is received' );
is( length( $data ), $MAX, 'dgram: message of exactly $MSG_MAX length' );

is( socketpair_send( $E, '' ), 0, 'dgram: empty message is not sent' );
is( $SOCK_ERR, SOCK_E_EMPTY, 'dgram: empty message sets SOCK_E_EMPTY' );

# empty datagram from a raw send() is skipped, not taken as EOF
send( $E, '', 0 );
socketpair_send( $E, 'after empty' );
is( socketpair_recv( $F, \$data ), 1, 'dgram: raw empty datagram is skipped' );
is( $data, 'after empty', 'dgram: message after a raw empty datagram' );
send( $E, '', 0 );
is( socketpair_recv( $F, \$data ), 0, 'dgram: only a raw empty datagram waiting returns 0' );
is( $SOCK_ERR, SOCK_E_AGAIN, 'dgram: only a raw empty datagram waiting sets SOCK_E_AGAIN' );

{
  local $Net::Tools::Socket::Pair::MSG_MAX = 100_000;
  socketpair_send( $E, 'z' x 100_000 );
}
{
  local $Net::Tools::Socket::Pair::MSG_MAX = 1000;
  is( socketpair_recv( $F, \$data ), 0, 'dgram: incoming message over $MSG_MAX returns 0' );
  is( $SOCK_ERR, SOCK_E_TOOBIG, 'dgram: incoming message over $MSG_MAX sets SOCK_E_TOOBIG' );
}
socketpair_send( $E, 'after big' );
is( socketpair_recv( $F, \$data ), 1, 'dgram: next message after a discarded one' );
is( $data, 'after big', 'dgram: oversized message was discarded whole' );

# full queue
$sent = 0;
$sent++ while socketpair_send( $E, 'q' x 1000 );
ok( $sent > 10, "dgram: queue filled after $sent messages (not limited by max_dgram_qlen)" );
is( $SOCK_ERR, SOCK_E_AGAIN, 'dgram: full queue sets SOCK_E_AGAIN' );
$read = 0;
$read++ while socketpair_recv( $F, \$data );
is( $read, $sent, 'dgram: every queued message is received' );

##############################################################################
# dgram: peer closed, no EOF on recv, EOF on send
##############################################################################

socketpair_send( $E, 'last words' );
close( $E );
is( socketpair_recv( $F, \$data ), 1, 'dgram: queued message is still read after the peer closed' );
is( $data, 'last words', 'dgram: queued message after close' );
is( socketpair_recv( $F, \$data ), 0, 'dgram: recv after the peer closed returns 0, no EOF' );
is( $SOCK_ERR, SOCK_E_AGAIN, 'dgram: recv after the peer closed sets SOCK_E_AGAIN' );
is( socketpair_send( $F, 'nobody' ), undef, 'dgram: send returns undef when the peer closed' );
is( $SOCK_ERR, SOCK_E_EOF, 'dgram: peer closed sets SOCK_E_EOF on send (ECONNREFUSED)' );
is( socketpair_send( $F, 'nobody' ), undef, 'dgram: next send returns undef too' );
is( $SOCK_ERR, SOCK_E_EOF, 'dgram: next send sets SOCK_E_EOF (ENOTCONN)' );
close( $F );

# one dgram write end shared by many writers (as forked processes do)
my ( $R, $W ) = socketpair_create( 'dgram' );
open( my $W2, '>&', $W ) or die "dup: $!";
socketpair_send( $W,  'from 1' );
socketpair_send( $W2, 'from 2' );
close( $W );
socketpair_send( $W2, 'from 2 again' );
@got = ();
push @got, $data while socketpair_recv( $R, \$data );
is_deeply( \@got, [ 'from 1', 'from 2', 'from 2 again' ], 'dgram: shared write end, one reader' );
close( $W2 );
close( $R );

##############################################################################
# no SIGPIPE: MSG_NOSIGNAL, or the ignored SIGPIPE fallback (macOS)
##############################################################################

ok( $Net::Tools::Socket::Pair::MSG_NOSIGNAL > 0, 'MSG_NOSIGNAL is available here' );

# linux never raises SIGPIPE for AF_UNIX seqpacket and dgram sockets (BSDs
# do), so a stream socketpair is used here, which raises SIGPIPE on EPIPE
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );
for my $nosig ( $Net::Tools::Socket::Pair::MSG_NOSIGNAL, 0 )
  {
  my $how = $nosig ? 'MSG_NOSIGNAL' : 'fallback';
  local $Net::Tools::Socket::Pair::MSG_NOSIGNAL = $nosig;

  my $pipes = 0;
  my $handler = sub { $pipes++ };
  local $SIG{ 'PIPE' } = $handler;

  socketpair( my $P, my $Q, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die "socketpair: $!";
  close( $Q );
  is( socketpair_send( $P, 'x' ), undef, "$how: send to a closed peer returns undef" );
  is( $SOCK_ERR, SOCK_E_EOF, "$how: EPIPE sets SOCK_E_EOF" );
  is( $pipes, 0, "$how: no SIGPIPE was raised" );
  is( $SIG{ 'PIPE' }, $handler, "$how: caller's SIGPIPE handler is restored" );
  close( $P );
  }

##############################################################################

done_testing();
