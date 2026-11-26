#!/usr/bin/perl
##############################################################################
#
#  Net::Tools test suite -- Net::Tools::Socket
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
use strict;
use lib 'lib', '../lib';
use Test::More;
use Socket;
use IO::Handle;
use Net::Tools::Socket;
use Net::Tools::Socket::Err;

ok( defined $Net::Tools::Socket::VERSION, 'Net::Tools::Socket loaded' );

my $TIMEOUT = 10;

sub make_pair
{
  socketpair( my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or return ();
  $a->autoflush( 1 );
  $b->autoflush( 1 );
  return ( $a, $b );
}

my ( $A, $B ) = make_pair();
plan( skip_all => "socketpair() is not available: $!" ) unless $A;

##############################################################################
# socket_can_read() / socket_can_write()
##############################################################################

ok(   socket_can_write( $A, $TIMEOUT ), 'socket_can_write() on an idle socket' );
ok( ! socket_can_read(  $B, 0 ),        'socket_can_read() is false with no pending data' );

##############################################################################
# socket_write() / socket_read() / socket_print()
##############################################################################

is( socket_print( $A, 'hello', $TIMEOUT ), 5, 'socket_print() returns bytes written' );

ok( socket_can_read( $B, $TIMEOUT ), 'socket_can_read() is true with pending data' );

my $data;
is( socket_read( $B, \$data, 5, $TIMEOUT ), 5, 'socket_read() returns bytes read' );
is( $data, 'hello', 'socket_read() returned the data' );

is( socket_write( $A, 'abcdef', 6, $TIMEOUT ), 6, 'socket_write() returns bytes written' );
socket_read( $B, \$data, 6, $TIMEOUT );
is( $data, 'abcdef', 'socket_write()/socket_read() round trip' );

# length larger than the data is refused
is( socket_write( $A, 'abc', 10, $TIMEOUT ), undef, 'socket_write() refuses length larger than data' );
is( $SOCK_ERR, SOCK_E_INVAL, 'socket_write() reports SOCK_E_INVAL for length larger than data' );
ok( ! socket_can_read( $B, 0 ), 'socket_write() with length larger than data writes nothing' );

# partial write: only the given length is sent
socket_write( $A, 'abcdef', 3, $TIMEOUT );
socket_read( $B, \$data, 3, $TIMEOUT );
is( $data, 'abc', 'socket_write() honours the given length' );

# binary data survives untouched
my $bin = join '', map { chr } 0 .. 255;
socket_write( $A, $bin, length( $bin ), $TIMEOUT );
socket_read( $B, \$data, length( $bin ), $TIMEOUT );
is( $data, $bin, 'socket_write()/socket_read() are binary clean' );

##############################################################################
# socket_read() timing out
##############################################################################

is( socket_read( $B, \$data, 1, 1 ), undef, 'socket_read() returns undef on timeout' );

##############################################################################
# socket_write_message() / socket_read_message()
##############################################################################

ok( socket_write_message( $A, 'message here', $TIMEOUT ), 'socket_write_message()' );

my $msg = socket_read_message( $B, $TIMEOUT );
is( $msg,      'message here', 'socket_read_message() returned the message' );
is( $SOCK_ERR, undef,          'socket_read_message() reported no error' );

socket_write_message( $A, 'scalar context', $TIMEOUT );
is( scalar socket_read_message( $B, $TIMEOUT ), 'scalar context',
    'socket_read_message() in scalar context returns the data' );

# empty message
ok( socket_write_message( $A, '', $TIMEOUT ), 'socket_write_message() with empty data' );
my $emsg = socket_read_message( $B, $TIMEOUT );
is( $emsg,     '',    'socket_read_message() returns empty string for empty message' );
is( $SOCK_ERR, undef, 'socket_read_message() reports no error for empty message' );

# undef data is sent as an empty message
ok( socket_write_message( $A, undef, $TIMEOUT ), 'socket_write_message() with undef data' );
is( socket_read_message( $B, $TIMEOUT ), '', 'socket_read_message() returns empty string for undef data' );

# maxlen 0 or negative means the default
socket_write_message( $A, 'default maxlen', $TIMEOUT );
is( socket_read_message( $B, $TIMEOUT, 0 ), 'default maxlen', 'socket_read_message() with maxlen 0 uses the default' );
socket_write_message( $A, 'negative maxlen', $TIMEOUT );
is( socket_read_message( $B, $TIMEOUT, -1 ), 'negative maxlen', 'socket_read_message() with negative maxlen uses the default' );
socket_write_message( $A, 'exact', $TIMEOUT );
is( socket_read_message( $B, $TIMEOUT, 5 ), 'exact', 'socket_read_message() accepts a message of exactly maxlen' );

# big message, spanning several reads
my $big = 'x' x 100_000; # must stay below the socket buffer size, nobody reads concurrently
ok( socket_write_message( $A, $big, $TIMEOUT ), 'socket_write_message() with a big message' );
is( scalar socket_read_message( $B, $TIMEOUT ), $big, 'socket_read_message() reassembles a big message' );

##############################################################################
# socket_write_message() single write (up to $WRITE_MESSAGE_JOIN_MAX, length
# included) or two writes (length, then data) for longer messages
##############################################################################

# runs $code, returns how many socket_write() calls it made
sub count_writes
{
  my $code = shift;
  my $n    = 0;
  my $orig = \&Net::Tools::Socket::socket_write;
  no warnings 'redefine';
  local *Net::Tools::Socket::socket_write = sub { $n++; goto &$orig };
  $code->();
  return $n;
}

my $JOIN_MAX = $Net::Tools::Socket::WRITE_MESSAGE_JOIN_MAX;
is( $JOIN_MAX, 64 * 1024, 'WRITE_MESSAGE_JOIN_MAX default is 64 KiB' );

my $small = 's' x 100;
is( count_writes( sub { socket_write_message( $A, $small, $TIMEOUT ) } ), 1, 'small message is sent with one write' );
is( scalar socket_read_message( $B, $TIMEOUT ), $small, 'small single write message round trip' );

is( count_writes( sub { socket_write_message( $A, '', $TIMEOUT ) } ), 1, 'empty message is sent with one write' );
is( scalar socket_read_message( $B, $TIMEOUT ), '', 'empty single write message round trip' );

my $at_max = 'm' x ( $JOIN_MAX - 4 ); # length + data exactly at the limit
is( count_writes( sub { socket_write_message( $A, $at_max, $TIMEOUT ) } ), 1, 'message of exactly WRITE_MESSAGE_JOIN_MAX (length included) is sent with one write' );
is( scalar socket_read_message( $B, $TIMEOUT ), $at_max, 'message at the limit round trip' );

my $over_max = 'o' x ( $JOIN_MAX - 3 ); # one byte over the limit
is( count_writes( sub { socket_write_message( $A, $over_max, $TIMEOUT ) } ), 2, 'message one byte over WRITE_MESSAGE_JOIN_MAX is sent with two writes' );
is( scalar socket_read_message( $B, $TIMEOUT ), $over_max, 'message over the limit round trip' );

my $bin_over = join '', map { chr( $_ % 256 ) } 0 .. $JOIN_MAX;
is( count_writes( sub { socket_write_message( $A, $bin_over, $TIMEOUT ) } ), 2, 'binary message over the limit is sent with two writes' );
is( scalar socket_read_message( $B, $TIMEOUT ), $bin_over, 'two writes message is binary clean' );

{
  # the limit can be changed, 0 sends every message with two writes
  local $Net::Tools::Socket::WRITE_MESSAGE_JOIN_MAX = 0;
  is( count_writes( sub { socket_write_message( $A, $small, $TIMEOUT ) } ), 2, 'WRITE_MESSAGE_JOIN_MAX 0 sends a small message with two writes' );
  is( scalar socket_read_message( $B, $TIMEOUT ), $small, 'small two writes message round trip' );
}
{
  # a raised limit joins longer messages too
  local $Net::Tools::Socket::WRITE_MESSAGE_JOIN_MAX = 2 * $JOIN_MAX;
  is( count_writes( sub { socket_write_message( $A, $over_max, $TIMEOUT ) } ), 1, 'raised WRITE_MESSAGE_JOIN_MAX sends a longer message with one write' );
  is( scalar socket_read_message( $B, $TIMEOUT ), $over_max, 'raised limit single write round trip' );
}

# both paths in a row keep the stream in sync. nobody reads concurrently, after
# a long message the socket buffer has no room left, so read before the last one
socket_write_message( $A, 'first', $TIMEOUT );
socket_write_message( $A, $over_max, $TIMEOUT );
is( scalar socket_read_message( $B, $TIMEOUT ), 'first',   'mixed paths: first single write message' );
is( scalar socket_read_message( $B, $TIMEOUT ), $over_max, 'mixed paths: two writes message' );
socket_write_message( $A, 'last', $TIMEOUT );
is( scalar socket_read_message( $B, $TIMEOUT ), 'last',    'mixed paths: last single write message' );
ok( ! socket_can_read( $B, 0 ), 'mixed paths: nothing left in the stream' );

# a refused message writes nothing on either path
is( count_writes( sub { socket_write_message( $A, "\x{263a}" x 10, $TIMEOUT ) } ), 0, 'wide characters are refused before any write' );

##############################################################################
# socket_read_message() error reporting
##############################################################################

# maxlen smaller than the incoming message
socket_write_message( $A, 'too long for maxlen', $TIMEOUT );
is( socket_read_message( $B, $TIMEOUT, 4 ), undef, 'socket_read_message() returns undef when over maxlen' );
is( $SOCK_ERR, SOCK_E_TOOBIG, 'socket_read_message() reports SOCK_E_TOOBIG when over maxlen' );
# the message is left unread, the stream is out of sync, use a new pair from here
close( $A );
close( $B );
( $A, $B ) = make_pair();

# closed socket: end of communication
my ( $C, $D ) = make_pair();
close( $C );
is( socket_read_message( $D, $TIMEOUT ), undef, 'socket_read_message() returns undef on a closed socket' );
is( $SOCK_ERR, SOCK_E_EOF, 'socket_read_message() reports SOCK_E_EOF on a closed socket' );
close( $D );

# truncated length header -- socket_read() gives up on the short read, so this
# surfaces as end of communication rather than a bad length
my ( $E, $F ) = make_pair();
socket_print( $E, "\x00\x00", $TIMEOUT );
close( $E );
is( socket_read_message( $F, $TIMEOUT ), undef, 'socket_read_message() returns undef on a truncated header' );
is( $SOCK_ERR, SOCK_E_EOF, 'socket_read_message() reports SOCK_E_EOF on a truncated header' );
close( $F );

# a timeout in the middle of the length bytes leaves the stream out of sync
my ( $K, $L ) = make_pair();
socket_print( $K, substr( pack( 'N', 3 ), 0, 2 ), $TIMEOUT ); # first half of the length
is( socket_read_message( $L, 0.2 ), undef, 'socket_read_message() returns undef on a timeout in the middle of the length' );
is( $SOCK_ERR, SOCK_E_TIMEOUT, 'socket_read_message() reports SOCK_E_TIMEOUT in the middle of the length' );
socket_print( $K, substr( pack( 'N', 3 ), 2 ) . 'abc', $TIMEOUT ); # second half and data
is( socket_read_message( $L, $TIMEOUT, 100 ), undef, 'the consumed first half of the length puts the stream out of sync' );
is( $SOCK_ERR, SOCK_E_TOOBIG, 'out of sync stream reads a wrong length' );
close( $K );
close( $L );

# announced length larger than what actually arrives
my ( $G, $H ) = make_pair();
socket_print( $G, pack( 'N', 10 ) . 'short', $TIMEOUT );
close( $G );
is( socket_read_message( $H, $TIMEOUT ), undef, 'socket_read_message() returns undef on a truncated body' );
is( $SOCK_ERR, SOCK_E_EOF, 'socket_read_message() reports SOCK_E_EOF on a truncated body' );
close( $H );

##############################################################################
# timeouts, closed and descriptor-less handles, wide characters
##############################################################################

is( socket_read( $B, \$data, 1, 0 ), undef, 'socket_read() with timeout 0 and no data returns undef at once' );
is( $SOCK_ERR, SOCK_E_TIMEOUT, 'socket_read() with timeout 0 reports SOCK_E_TIMEOUT' );
socket_print( $A, 'z', $TIMEOUT );
is( socket_read( $B, \$data, 1, 0 ), 1, 'socket_read() with timeout 0 reads pending data' );

is( socket_write_message( $A, "\x{263a}", $TIMEOUT ), undef, 'socket_write_message() refuses wide characters' );
is( $SOCK_ERR, SOCK_E_INVAL, 'socket_write_message() reports SOCK_E_INVAL for wide characters' );
ok( ! socket_can_read( $B, 0 ), 'socket_write_message() with wide characters writes nothing, not even the length' );

is( socket_write( $A, "ab\x{263a}", 3, $TIMEOUT ), undef, 'socket_write() refuses wide characters' );
is( $SOCK_ERR, SOCK_E_INVAL, 'socket_write() reports SOCK_E_INVAL for wide characters' );
is( socket_print( $A, "\x{263a}", $TIMEOUT ), undef, 'socket_print() refuses wide characters' );
is( $SOCK_ERR, SOCK_E_INVAL, 'socket_print() reports SOCK_E_INVAL for wide characters' );
ok( ! socket_can_read( $B, 0 ), 'socket_write() and socket_print() with wide characters write nothing' );

# characters up to 255 in an upgraded (utf8 flagged) string are sent as bytes
my $latin1 = "caf\x{e9}";
utf8::upgrade( $latin1 );
is( socket_print( $A, $latin1, $TIMEOUT ), 4, 'socket_print() sends an upgraded latin1 string as 4 bytes' );
socket_read( $B, \$data, 4, $TIMEOUT );
is( $data, "caf\xe9", 'socket_print() upgraded latin1 string arrives as bytes' );
ok( socket_write_message( $A, $latin1, $TIMEOUT ), 'socket_write_message() sends an upgraded latin1 string' );
is( socket_read_message( $B, $TIMEOUT ), "caf\xe9", 'socket_write_message() upgraded latin1 string arrives as bytes' );

my ( $I, $J ) = make_pair();
close( $I );
is( socket_can_read(  $I, $TIMEOUT ), undef, 'socket_can_read() on a closed handle returns undef' );
is( socket_can_write( $I, $TIMEOUT ), undef, 'socket_can_write() on a closed handle returns undef' );
is( socket_read_message( $I, $TIMEOUT ), undef, 'socket_read_message() on a closed handle returns undef' );
is( $SOCK_ERR, undef, 'socket_read_message() on a closed handle sets no error' );
close( $J );

open( my $MEM, '<', \'in-memory' );
is( eval { socket_can_read( $MEM, $TIMEOUT ) }, undef, 'socket_can_read() on an in-memory handle returns undef' );
is( $@, '', 'socket_can_read() on an in-memory handle does not die' );
close( $MEM );

##############################################################################
# export tags
##############################################################################

ok( eval q{ package T8::All;  use Net::Tools::Socket qw( :all );  defined &socket_read }, 'use Net::Tools::Socket qw( :all ) imports functions' );
ok( eval q{ package T8::None; use Net::Tools::Socket qw( :none ); 1 } && ! defined &T8::None::socket_read, 'use Net::Tools::Socket qw( :none ) imports nothing' );

close( $A );
close( $B );

##############################################################################

done_testing();
