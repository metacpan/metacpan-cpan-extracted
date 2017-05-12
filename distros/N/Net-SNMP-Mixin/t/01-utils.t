#!perl -T

use strict;
use warnings;
use Test::More;

plan tests => 55;

use_ok('Net::SNMP');

use_ok('Net::SNMP::Mixin::Util');
ok( !main->can('normalize_mac'), 'normalize_mac not exported by default' );
ok( !main->can('hex2octet'),     'hex2octet not exported by default' );
ok( !main->can('idx2val'),       'idx2val not exported by default' );
ok( !main->can('push_error'),    'push_error not exported by default' );
ok( !main->can('get_init_slot'), 'get_init_slot not exported by default' );

use_ok( 'Net::SNMP::Mixin::Util',
  qw/normalize_mac hex2octet idx2val push_error get_init_slot/ );

ok( main->can('normalize_mac'), 'normalize_mac imported' );
ok( main->can('hex2octet'),     'hex2octet imported' );
ok( main->can('idx2val'),       'idx2val imported' );
ok( main->can('push_error'),    'push_error imported' );
ok( main->can('get_init_slot'), 'get_init_slot imported' );

# ----------------------------------
# test mac normalization
# ----------------------------------
my @mac;
@mac = ( 'aabbccddeeff', 'AA:BB:CC:DD:EE:FF', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( 'AABBCCDDEEFF', 'AA:BB:CC:DD:EE:FF', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( '0:0:0:0:0:0', '00:00:00:00:00:00', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( '0a:a:a:a:a:a', '0A:0A:0A:0A:0A:0A', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( 'a:a:a:a:a:0a', '0A:0A:0A:0A:0A:0A', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( '0a:a:a:a:a:0a', '0A:0A:0A:0A:0A:0A', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( '0:0:0:0:0:0', '00:00:00:00:00:00', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( '00:0:a0:0:0:F0', '00:00:A0:00:00:F0', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( '00-0b-a0-0c-0F-00', '00:0B:A0:0C:0F:00', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( '000ba0-0c0F00', '00:0B:A0:0C:0F:00', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( '000b.a00c.0F00', '00:0B:A0:0C:0F:00', );
is( normalize_mac( $mac[0] ), $mac[1], "$mac[0] -> $mac[1]" );

@mac = ( pack( 'C6', ( 0, 16, 17, 127, 128, 255 ) ), '00:10:11:7F:80:FF', );
is( normalize_mac( $mac[0] ), $mac[1], "pack 'C6', ... -> $mac[1]" );

@mac = ( undef, undef );
is( normalize_mac( $mac[0] ), $mac[1], "undef returns undef" );

@mac = ( 'AABBCCDDEE', undef );
is( normalize_mac( $mac[0] ),
  $mac[1], "wrong format '$mac[0]' returns undef" );

@mac = ( 'AABBCCDDEEFFAA', undef );
is( normalize_mac( $mac[0] ),
  $mac[1], "wrong format '$mac[0]' returns undef" );

@mac = ( 'AABBCCDDEEGG', undef );
is( normalize_mac( $mac[0] ),
  $mac[1], "wrong format '$mac[0]' returns undef" );

@mac = ( '00::a0:0:0:F0', undef, );
is( normalize_mac( $mac[0] ),
  $mac[1], "wrong format '$mac[0]' returns undef" );

@mac = ( '000ba0_0c0F00', undef, );
is( normalize_mac( $mac[0] ),
  $mac[1], "wrong format '$mac[0]' returns undef" );

@mac = ( pack( 'C5', ( 0, 16, 17, 127, 128 ) ), undef );
is( normalize_mac( $mac[0] ),
  $mac[1], "wrong format 'pack \"C5, ...\"' returns undef" );

@mac = ( pack( 'C7', ( 0, 16, 17, 127, 128, 255, 0 ) ), undef );
is( normalize_mac( $mac[0] ),
  $mac[1], "wrong format 'pack \"C7, ...\"' returns undef" );

# ----------------------------------
# test hex 2 octet conversion
# ----------------------------------
my @hex;
@hex = ( '0x' . unpack( 'H*', 'FOObarBAZ' ), 'FOObarBAZ' );
is( hex2octet( $hex[0] ), $hex[1], "$hex[0] -> $hex[1]" );

@hex = ( sprintf( '%x', 1234567890 ), sprintf( '%x', 1234567890 ) );
is( hex2octet( $hex[0] ), $hex[1],
  "wrong format '$hex[0]', no translation " );

@hex = ( '0xGG', '0xGG' );
is( hex2octet( $hex[0] ), $hex[1],
  "wrong format '$hex[0]', no translation " );

# ----------------------------------
# test idx2val
# ----------------------------------
my $vbl = {
  '1.2.3.41.35.0.1.0.1' => 'foo',
  '1.2.3.41.35.0.2.0.1' => 'bar',
  '1.2.3.41.35.0.3.0.1' => 'baz',
  '1.3.2.40'            => 'wrong oid',
};

my $base_oid = '1.2.3.41.35';

my $res = {
  '0.1.0.1' => 'foo',
  '0.2.0.1' => 'bar',
  '0.3.0.1' => 'baz',
};

is_deeply( idx2val( $vbl, $base_oid, undef, undef ),
  $res, 'idx2val without pre and tail' );

$res = {
  '0.1.0' => 'foo',
  '0.2.0' => 'bar',
  '0.3.0' => 'baz',
};

is_deeply( idx2val( $vbl, $base_oid, undef, 1 ), $res,
  'idx2val with tail 1' );

$res = {
  '1.0.1' => 'foo',
  '2.0.1' => 'bar',
  '3.0.1' => 'baz',
};

is_deeply( idx2val( $vbl, $base_oid, 1, undef ), $res, 'idx2val with pre 1' );

$res = {
  '1' => 'foo',
  '2' => 'bar',
  '3' => 'baz',
};

is_deeply( idx2val( $vbl, $base_oid, 1, 2 ),
  $res, 'idx2val with pre 1 and tail 2' );

$base_oid = '1.2.3.41';

$res = {
  '1' => 'foo',
  '2' => 'bar',
  '3' => 'baz',
};

is_deeply( idx2val( $vbl, $base_oid, 2, 2 ),
  $res, 'idx2val with pre 2 and tail 2' );

# test oids with leading or trailing space, grml
$vbl = {
  '1.2.3.41.35.1  '      => 'foo',
  ' 1.2.3.41.35.2'       => 'bar',
  '   1.2.3.41.35.3    ' => 'baz',
};

$base_oid = '1.2.3.41.35';

$res = {
  '1' => 'foo',
  '2' => 'bar',
  '3' => 'baz',
};

is_deeply( idx2val( $vbl, $base_oid, undef, undef ),
  $res, 'idx2val with leading and trailing whitespace' );

eval { idx2val( $vbl, undef ) };
like( $@, qr/missing attribute/, 'baseoid undefined' );

eval { idx2val(undef) };
like( $@, qr/missing attribute/, 'var_bind_list undefined' );

eval { idx2val( $vbl, $base_oid, -1, undef ) };
like( $@, qr/wrong format/, 'pre negative' );

eval { idx2val( $vbl, $base_oid, 1, -2 ) };
like( $@, qr/wrong format/, 'tail negative' );

# ----------------------------------
# test push_error
# ----------------------------------
use_ok('Net::SNMP::Mixin');
ok( Net::SNMP->can('errors'), 'errors exported by default into Net::SNMP' );

eval { push_error() };
like( $@, qr/missing attribute 'session'/, 'called without params' );

my $session = Net::SNMP->new;
eval { push_error($session) };
like( $@, qr/missing attribute 'error_msg'/, 'called without error_msg' );

ok( push_error( $session, 'my error' ), 'pushed error' );
is( $session->errors(1), 'my error', 'test errors()' );
is( $session->errors(),  '',         'errors() cleared' );


# ----------------------------------
# test get_init_slot
# ----------------------------------
eval { get_init_slot(undef) };
like( $@, qr/missing attribute 'session'/, 'called without session' );

is_deeply({}, get_init_slot($session), 'init_slot is empty');

# vim: ft=perl sw=2
