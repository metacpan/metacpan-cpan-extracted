#!/usr/bin/perl
##############################################################################
#
#  Net::Tools test suite -- Net::Tools::Socket::Protocols
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
use Data::Tools;
use Net::Tools::Socket;
use Net::Tools::Socket::Protocols;
use Net::Tools::Socket::Err;

ok( defined $Net::Tools::Socket::Protocols::VERSION, 'Net::Tools::Socket::Protocols loaded' );

my $TIMEOUT = 10;

sub make_pair
{
  socketpair( my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or return ();
  $a->autoflush( 1 );
  $b->autoflush( 1 );
  return ( $a, $b );
}

sub have_module
{
  my $need = shift;
  return 1 unless $need;
  local $@;
  return eval { my $fn = perl_package_to_file( $need ); require $fn; 1 };
}

my ( $A, $B ) = make_pair();
plan( skip_all => "socketpair() is not available: $!" ) unless $A;

##############################################################################
# protocol types and the modules they need
#   'b' binary        -- no module needed
#   'h' hash2str      -- no module needed
#   'H' hash2str_url  -- no module needed
#   'p' Storable      -- core, forbidden by default (unsafe on untrusted data)
#   'j' JSON
#   'e' Sereal        -- optional
#   's' Data::Stacker -- optional
##############################################################################

my %NEEDS = (
            'h' => undef,
            'H' => undef,
            'j' => 'JSON',
            'e' => 'Sereal',
            's' => 'Data::Stacker',
            );

##############################################################################
# round trip of a hash through every available default protocol
##############################################################################

my $HR = { alpha => 'one', beta => 'two words', gamma => '3' };

for my $ptype ( sort keys %NEEDS )
{
  SKIP:
  {
    my $need = $NEEDS{ $ptype };
    skip( "$need is not installed, protocol '$ptype' unavailable", 3 ) unless have_module( $need );

    ok( socket_protocol_write_message( $A, $ptype, $HR, $TIMEOUT ),
        "socket_protocol_write_message() protocol '$ptype'" );
    is( $SOCK_ERR, undef, "protocol '$ptype' write leaves no error" );

    is_deeply( scalar( socket_protocol_read_message( $B, $TIMEOUT ) ), $HR, "protocol '$ptype' round trip" );
  }
}

##############################################################################
# binary protocol carries plain data, not a hash
##############################################################################

ok( socket_protocol_write_message( $A, 'b', 'plain binary payload', $TIMEOUT ),
    "socket_protocol_write_message() protocol 'b'" );
is( socket_protocol_read_message( $B, $TIMEOUT ), 'plain binary payload', "protocol 'b' round trip" );
is( $SOCK_ERR, undef, "protocol 'b' read leaves no error" );

my $raw = join '', map { chr } 0 .. 255;
socket_protocol_write_message( $A, 'b', $raw, $TIMEOUT );
is( socket_protocol_read_message( $B, $TIMEOUT ), $raw, "protocol 'b' is binary clean" );

ok( socket_protocol_write_message( $A, 'b', '', $TIMEOUT ), "protocol 'b' accepts an empty payload" );
is( socket_protocol_read_message( $B, $TIMEOUT ), '', "protocol 'b' empty payload reads back as ''" );

ok( socket_protocol_write_message( $A, 'b', undef, $TIMEOUT ), "protocol 'b' accepts undef payload" );
is( socket_protocol_read_message( $B, $TIMEOUT ), '', "protocol 'b' undef payload reads back as ''" );

for my $ref ( {}, [], \'x', sub { 1 } )
{
  is( socket_protocol_write_message( $A, 'b', $ref, $TIMEOUT ), undef, "protocol 'b' rejects a " . ref( $ref ) . " reference" );
  is( $SOCK_ERR, SOCK_E_INVAL, "protocol 'b' " . ref( $ref ) . " reference sets SOCK_E_INVAL" );
}

##############################################################################
# write argument checking
##############################################################################

is( socket_protocol_write_message( $A, 'Z', { a => 1 }, $TIMEOUT ), undef, 'socket_protocol_write_message() rejects unknown protocol' );
is( $SOCK_ERR, SOCK_E_PROTO, 'unknown protocol sets SOCK_E_PROTO' );
like( $SOCK_ERRSTR, qr/unknown or forbidden PROTOCOL_TYPE \[hex:5a\]/, 'unknown protocol error text' );

# protocol type must be exactly one character, nothing is sent otherwise
for my $t ( [ 'jj', '6a6a' ], [ 'json', '6a736f6e' ], [ '', '' ], [ undef, '' ] )
{
  my ( $ptype, $hex ) = @$t;
  my $name = defined $ptype ? "'$ptype'" : 'undef';
  is( socket_protocol_write_message( $A, $ptype, { a => 1 }, $TIMEOUT ), undef, "socket_protocol_write_message() rejects protocol type $name" );
  is( $SOCK_ERR, SOCK_E_PROTO, "protocol type $name sets SOCK_E_PROTO" );
  like( $SOCK_ERRSTR, qr/PROTOCOL_TYPE \[hex:$hex\]/, "protocol type $name error text shows [hex:$hex]" );
}

is( socket_protocol_write_message( $A, 'h', 'not a hash ref', $TIMEOUT ), undef, 'socket_protocol_write_message() requires a hash ref for non-binary protocols' );
is( $SOCK_ERR, SOCK_E_INVAL, 'non hash ref sets SOCK_E_INVAL' );

is( socket_protocol_write_message( $A, 'h', [ 1, 2 ], $TIMEOUT ), undef, 'socket_protocol_write_message() rejects an array ref for non-binary protocols' );
is( $SOCK_ERR, SOCK_E_INVAL, 'array ref sets SOCK_E_INVAL' );

SKIP:
{
  skip( 'JSON is not installed', 4 ) unless have_module( 'JSON' );

  # pack dies inside the serializer, error is reported, caller's $@ is kept
  $@ = 'caller error';
  is( socket_protocol_write_message( $A, 'j', { a => \*STDOUT }, $TIMEOUT ), undef, 'pack failure returns undef' );
  is( $SOCK_ERR, SOCK_E_PROTO, 'pack failure sets SOCK_E_PROTO' );
  unlike( $SOCK_ERRSTR, qr/ at \S+ line \d+|\n/, 'pack failure error text has no location and no newline' );
  is( $@, 'caller error', 'pack failure leaves the caller $@ alone' );
}

$@ = 'caller error';
ok( socket_protocol_write_message( $A, 'h', $HR, $TIMEOUT ), 'write with a caller $@ set' );
is( $@, 'caller error', 'successful write leaves the caller $@ alone' );
is_deeply( scalar( socket_protocol_read_message( $B, $TIMEOUT ) ), $HR, 'read back' );
is( $@, 'caller error', 'successful read leaves the caller $@ alone' );

##############################################################################
# incoming errors, the stream stays in sync
##############################################################################

socket_write_message( $A, "Z\nxyz", $TIMEOUT );
is( socket_protocol_read_message( $B, $TIMEOUT ), undef, 'socket_protocol_read_message() rejects unknown protocol' );
is( $SOCK_ERR, SOCK_E_PROTO, 'incoming unknown protocol sets SOCK_E_PROTO' );
unlike( $SOCK_ERRSTR, qr/Z/, 'incoming protocol byte is not copied into the error text' );

socket_write_message( $A, 'p' . 'anything', $TIMEOUT );
is( socket_protocol_read_message( $B, $TIMEOUT ), undef, "incoming 'p' (Storable) is forbidden by default" );
is( $SOCK_ERR, SOCK_E_PROTO, "incoming 'p' sets SOCK_E_PROTO" );

SKIP:
{
  skip( 'JSON is not installed', 6 ) unless have_module( 'JSON' );

  $@ = 'caller error';
  socket_write_message( $A, 'j{not json', $TIMEOUT );
  is( socket_protocol_read_message( $B, $TIMEOUT ), undef, 'undecodable payload returns undef' );
  is( $SOCK_ERR, SOCK_E_PROTO, 'undecodable payload sets SOCK_E_PROTO' );
  unlike( $SOCK_ERRSTR, qr/ at \S+ line \d+|\n/, 'unpack failure error text has no location and no newline' );
  is( $@, 'caller error', 'unpack failure leaves the caller $@ alone' );

  socket_write_message( $A, 'j[1,2]', $TIMEOUT );
  is( socket_protocol_read_message( $B, $TIMEOUT ), undef, 'non-hash payload returns undef' );
  like( $SOCK_ERRSTR, qr/expected HASH reference/, 'non-hash payload error text' );
}

ok( socket_protocol_write_message( $A, 'h', $HR, $TIMEOUT ), 'write after protocol errors' );
is_deeply( scalar( socket_protocol_read_message( $B, $TIMEOUT ) ), $HR, 'stream still in sync after protocol errors' );

# maxlen is passed down to socket_read_message()
socket_protocol_write_message( $A, 'b', 'x' x 100, $TIMEOUT );
is( socket_protocol_read_message( $B, $TIMEOUT, 10 ), undef, 'message longer than maxlen is rejected' );
is( $SOCK_ERR, SOCK_E_TOOBIG, 'message longer than maxlen sets SOCK_E_TOOBIG' );

##############################################################################
# socket_protocols_allow()
##############################################################################

# fresh pair, the TOOBIG message above leaves the old stream out of sync
close( $A );
close( $B );
( $A, $B ) = make_pair();

socket_protocols_allow( 'bh' );

ok( socket_protocol_write_message( $A, 'h', $HR, $TIMEOUT ), 'allowed protocol still works' );
is_deeply( scalar( socket_protocol_read_message( $B, $TIMEOUT ) ), $HR, 'allowed protocol round trip' );

is( socket_protocol_write_message( $A, 'H', $HR, $TIMEOUT ), undef, 'socket_protocols_allow() forbids the other protocols' );
is( $SOCK_ERR, SOCK_E_PROTO, 'forbidden protocol sets SOCK_E_PROTO' );

socket_write_message( $A, 'H' . hash2str_url( $HR ), $TIMEOUT );
is( socket_protocol_read_message( $B, $TIMEOUT ), undef, 'incoming forbidden protocol is rejected' );
is( $SOCK_ERR, SOCK_E_PROTO, 'incoming forbidden protocol sets SOCK_E_PROTO' );

socket_protocols_allow( 'b', 'H' ); # a list of strings is joined
ok( socket_protocol_write_message( $A, 'H', $HR, $TIMEOUT ), 'socket_protocols_allow() accepts a list of protocol strings' );
is_deeply( scalar( socket_protocol_read_message( $B, $TIMEOUT ) ), $HR, 'list allowed protocol round trip' );
is( socket_protocol_write_message( $A, 'h', $HR, $TIMEOUT ), undef, 'protocol left out of the list is forbidden' );

eval { socket_protocols_allow( 'bZ' ) };
like( $@, qr/unknown PROTOCOL_TYPE/, 'socket_protocols_allow() rejects unknown protocol types' );

socket_protocols_allow( 'p' );
ok( socket_protocol_write_message( $A, 'p', $HR, $TIMEOUT ), "'p' (Storable) works when allowed explicitly" );
is_deeply( scalar( socket_protocol_read_message( $B, $TIMEOUT ) ), $HR, "'p' round trip" );

socket_protocols_allow( '*' );
ok( socket_protocol_write_message( $A, 'h', $HR, $TIMEOUT ), 'socket_protocols_allow( "*" ) re-enables the protocols' );
is_deeply( scalar( socket_protocol_read_message( $B, $TIMEOUT ) ), $HR, 'protocol works again after "*"' );

# '*' leaves out 'p', a type after '*' is added, a type before it is replaced
is( socket_protocol_write_message( $A, 'p', $HR, $TIMEOUT ), undef, "'*' does not allow 'p'" );
is( $SOCK_ERR, SOCK_E_PROTO, "'p' after '*' sets SOCK_E_PROTO" );
socket_protocols_allow( '*p' );
ok( socket_protocol_write_message( $A, 'p', $HR, $TIMEOUT ), "'*p' allows 'p'" );
is_deeply( scalar( socket_protocol_read_message( $B, $TIMEOUT ) ), $HR, "'*p' 'p' round trip" );
ok( socket_protocol_write_message( $A, 'h', $HR, $TIMEOUT ), "'*p' allows the other types too" );
is_deeply( scalar( socket_protocol_read_message( $B, $TIMEOUT ) ), $HR, "'*p' 'h' round trip" );
socket_protocols_allow( 'p*' );
is( socket_protocol_write_message( $A, 'p', $HR, $TIMEOUT ), undef, "'p' before '*' is replaced by it" );

is( socket_protocols_allow( 'bh' ), 1, 'socket_protocols_allow() returns 1' );
eval { socket_protocols_allow( 'HZ' ) };
like( $@, qr/unknown PROTOCOL_TYPE/, 'socket_protocols_allow() confesses on an unknown type' );
ok( socket_protocol_write_message( $A, 'h', $HR, $TIMEOUT ), 'the allowed set is kept after a confess' );
is_deeply( scalar( socket_protocol_read_message( $B, $TIMEOUT ) ), $HR, 'kept allowed set round trip' );
is( socket_protocol_write_message( $A, 'H', $HR, $TIMEOUT ), undef, 'a type before the unknown one is not added' );

socket_protocols_allow();
is( socket_protocol_write_message( $A, 'b', 'x', $TIMEOUT ), undef, 'socket_protocols_allow() with no arguments forbids sending' );
socket_write_message( $A, 'bx', $TIMEOUT );
is( socket_protocol_read_message( $B, $TIMEOUT ), undef, 'socket_protocols_allow() with no arguments forbids receiving' );
is( $SOCK_ERR, SOCK_E_PROTO, 'forbidden after an empty call sets SOCK_E_PROTO' );
socket_protocols_allow( '*' );

##############################################################################
# error reporting on a dead socket and on empty messages
##############################################################################

my ( $C, $D ) = make_pair();
close( $C );
is( socket_protocol_read_message( $D, $TIMEOUT ), undef, 'socket_protocol_read_message() returns undef on a closed socket' );
is( $SOCK_ERR, SOCK_E_EOF, 'socket_protocol_read_message() sets SOCK_E_EOF on a closed socket' );
close( $D );

# a zero length message has no protocol type byte
my ( $E, $F ) = make_pair();
socket_write_message( $E, '', $TIMEOUT );
is( socket_protocol_read_message( $F, $TIMEOUT ), undef, 'socket_protocol_read_message() returns undef for an empty message' );
is( $SOCK_ERR, SOCK_E_EMPTY, 'socket_protocol_read_message() sets SOCK_E_EMPTY for an empty message' );
ok( socket_protocol_write_message( $E, 'h', $HR, $TIMEOUT ), 'write after an empty message' );
is_deeply( scalar( socket_protocol_read_message( $F, $TIMEOUT ) ), $HR, 'stream still in sync after SOCK_E_EMPTY' );

# a message with only the protocol type byte has an empty payload
socket_write_message( $E, 'h', $TIMEOUT );
is_deeply( scalar( socket_protocol_read_message( $F, $TIMEOUT ) ), {}, "'h' with an empty payload reads back as an empty hash" );
is( $SOCK_ERR, undef, "'h' with an empty payload sets no error" );
SKIP: {
  skip( 'JSON is not installed', 2 ) unless have_module( 'JSON' );
  socket_write_message( $E, 'j', $TIMEOUT );
  is( socket_protocol_read_message( $F, $TIMEOUT ), undef, "'j' with an empty payload returns undef" );
  is( $SOCK_ERR, SOCK_E_PROTO, "'j' with an empty payload sets SOCK_E_PROTO" );
}
close( $E );
close( $F );

##############################################################################
# list context returns the data and the protocol type
##############################################################################

socket_protocols_allow( '*' );
my ( $G, $H ) = make_pair();

socket_protocol_write_message( $G, 'h', $HR, $TIMEOUT );
my @lr = socket_protocol_read_message( $H, $TIMEOUT );
is( scalar( @lr ), 2, 'list context returns two values' );
is_deeply( $lr[ 0 ], $HR, 'list context first value is the data' );
is( $lr[ 1 ], 'h', 'list context second value is the protocol type' );

socket_protocol_write_message( $G, 'b', 'raw', $TIMEOUT );
my ( $ldata, $lptype ) = socket_protocol_read_message( $H, $TIMEOUT );
is( $ldata,  'raw', "list context 'b' data" );
is( $lptype, 'b',   "list context 'b' protocol type" );

socket_write_message( $G, '', $TIMEOUT );
@lr = socket_protocol_read_message( $H, $TIMEOUT );
is_deeply( \@lr, [ undef ], 'list context on error returns a single undef' );
is( $SOCK_ERR, SOCK_E_EMPTY, 'list context on error sets $SOCK_ERR' );

socket_write_message( $G, 'x', $TIMEOUT );
my ( $edata, $eptype ) = socket_protocol_read_message( $H, $TIMEOUT );
is( $eptype, undef, 'list context on error gives no protocol type' );
is( $SOCK_ERR, SOCK_E_PROTO, 'list context unknown protocol sets SOCK_E_PROTO' );

close( $G );
close( $H );

close( $A );
close( $B );

##############################################################################

done_testing();
