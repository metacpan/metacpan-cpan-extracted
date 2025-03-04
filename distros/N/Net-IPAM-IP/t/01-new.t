#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::IP') || print "Bail out!\n"; }

can_ok( 'Net::IPAM::IP', 'new' );

# valid
foreach my $txt (qw/:: 0.0.0.0 fE80::0:1 1.2.3.4 ::ffff:127.0.0.1 ::ff:0 caFe::/) {
  ok( Net::IPAM::IP->new($txt), "is valid ($txt)" );
}

# invalid
foreach my $txt (
  qw/010.0.0.1 10.000.0.1 : ::ffff:1.2.3.4.5 ::cafe::affe cafe::: cafe::1:: cafe::1: :cafe:: ::cafe::
  cafe::1:2:3:4:5:6:7:8 1:2:3:4:5:6:7:8:9 ::1.2.3.4 cafe:affe:1.2.3.4 ::ff:1.2.3.4 ::dddd:1.2.3.4/
  )
{
  is( Net::IPAM::IP->new($txt), undef, "is invalid ($txt)" );
}

is( Net::IPAM::IP->new_from_bytes("\xff\xff\xff\xff"),                  '255.255.255.255', "new_from_bytes" );
is( Net::IPAM::IP->new_from_bytes( pack( 'C4', 192, 168, 0, 1 ) ),      '192.168.0.1',     "new_from_bytes" );
is( Net::IPAM::IP->new_from_bytes( pack( 'C16', 0xfe, 0x10 ) ),         'fe10::',          "new_from_bytes" );
is( Net::IPAM::IP->new_from_bytes( pack( 'N4', 0x20010db8, 0, 0, 1 ) ), '2001:db8::1',     "new_from_bytes" );

is( Net::IPAM::IP->new('0e80::1')->to_string, 'e80::1',  'to_string e80::1' );
is( Net::IPAM::IP->new('fe80::1')->to_string, 'fe80::1', 'to_string fe80::1' );
is( Net::IPAM::IP->new('1.2.3.4')->to_string, '1.2.3.4', 'to_string 1.2.3.4' );
is( Net::IPAM::IP->new('0.0.0.0')->to_string, '0.0.0.0', 'to_string 0.0.0.0' );
is( Net::IPAM::IP->new('1.1.1.1')->to_string, '1.1.1.1', 'to_string 1.1.1.1' );

is( Net::IPAM::IP->new('::ffff:127.0.0.1')->to_string, '::ffff:127.0.0.1', 'to_string ::ffff:127.0.0.1' );
is( Net::IPAM::IP->new('::cafe:affe')->to_string,      '::cafe:affe',      'to_string ::cafe:affe' );

ok( !Net::IPAM::IP->new('::12345'),   'undefined ::12345' );
ok( !Net::IPAM::IP->new('::1.2.3.4'), 'undefined ::1.2.3.4' );
ok( !Net::IPAM::IP->new('ffgd::1'),   'undefined ffgd::1' );
ok( !Net::IPAM::IP->new('fe80:::'),   'undefined fe80:::' );

ok( !Net::IPAM::IP->new('127.0.0.X'), 'undefined 127.0.0.X' );
ok( !Net::IPAM::IP->new('300.0.0.1'), 'undefined 300.0.0.1' );
ok( !Net::IPAM::IP->new('030.0.0.1'), 'undefined 030.0.0.1' );

is( Net::IPAM::IP->new('fe80::1')->version,          6, 'version fe80::1' );
is( Net::IPAM::IP->new('1.2.3.4')->version,          4, 'version 1.2.3.4' );
is( Net::IPAM::IP->new('::ffff:127.0.0.1')->version, 6, 'version ::ffff:127.0.0.1' );
is( Net::IPAM::IP->new('::1:2')->version,            6, 'version ::1:2' );
is( Net::IPAM::IP->new('::ff00')->version,           6, 'version ::ff00' );

is( Net::IPAM::IP->new('::ffff:127.0.0.1')->is4in6, 1, 'is4in6 ::ffff:127.0.0.1' );
ok( !Net::IPAM::IP->new('::1:2')->is4in6,  'not is4in6 ::1:2' );
ok( !Net::IPAM::IP->new('::ff00')->is4in6, 'not is4in6 ::ff00' );

is( Net::IPAM::IP->new('fe80::1')->expand, 'fe80:0000:0000:0000:0000:0000:0000:0001', 'expand fe80::1' );
is( Net::IPAM::IP->new('1.2.3.4')->expand, '001.002.003.004',                         'expand 1.2.3.4' );
is(
  Net::IPAM::IP->new('::ffff:127.0.0.1')->expand,
  '0000:0000:0000:0000:0000:ffff:7f00:0001',
  'expand ::ffff:127.0.0.1'
);

is(
  Net::IPAM::IP->new('fe80::1')->reverse,
  '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.f',
  'reverse fe80::1'
);
is( Net::IPAM::IP->new('1.2.3.4')->reverse, '4.3.2.1', 'reverse 1.2.3.4' );
is(
  Net::IPAM::IP->new('::ffff:127.0.0.1')->reverse,
  '1.0.0.0.0.0.f.7.f.f.f.f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0',
  'reverse ::ffff:127.0.0.1'
);

my $bytes_v4   = "\x0a\x00\x00\x01";
my $bytes_v4m6 = "\x00" x 10 . "\xff\xff\x7f\x00\x00\x01";
my $bytes_v6   = "\xfe\x80" . "\x00" x 13 . "\x01";

is( Net::IPAM::IP->new_from_bytes($bytes_v4)->to_string,   '10.0.0.1',         'new_from_bytes() v4' );
is( Net::IPAM::IP->new_from_bytes($bytes_v4m6)->to_string, '::ffff:127.0.0.1', 'new_from_bytes() v4mappedv6' );
is( Net::IPAM::IP->new_from_bytes($bytes_v6)->to_string,   'fe80::1',          'new_from_bytes() v6' );

# overload '""'
is( Net::IPAM::IP->new_from_bytes($bytes_v4),   '10.0.0.1',         'new_from_bytes() v4' );
is( Net::IPAM::IP->new_from_bytes($bytes_v4m6), '::ffff:127.0.0.1', 'new_from_bytes() v4mappedv6' );
is( Net::IPAM::IP->new_from_bytes($bytes_v6),   'fe80::1',          'new_from_bytes() v6' );

# regression for 'fe80::ffff'
$bytes_v6 = Net::IPAM::IP->new('fe80::ffff')->bytes;
ok( Net::IPAM::IP->new_from_bytes($bytes_v6)->to_string eq 'fe80::ffff', 'new_from_bytes() v6' );

my $obj;
$obj = Net::IPAM::IP->new('1.2.3.4');
is_deeply( $obj, $obj->new_from_bytes( $obj->bytes ), 'clone IPv4' );
$obj = Net::IPAM::IP->new('2001:db8::1');
is_deeply( $obj, $obj->new_from_bytes( $obj->bytes ), 'clone IPv6' );

done_testing();
