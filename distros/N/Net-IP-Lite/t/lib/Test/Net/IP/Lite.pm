use strict;
use warnings;

package Test::Net::IP::Lite;
use Carp qw(croak);

use Test::More;
use Test::Exception;

use base 'Exporter';

our @EXPORT = qw(
	invalid die_on_invalid
	@valid_ipv4 @valid_ipv6 @valid_ipv6_ipv4 @valid_ipv6_ipv4 @invalid_ipv4
	@invalid_ipv6 @invalid_ipv6_ipv4 @short_ipv6 @short_ipv6_rev @expand_ipv6
	@short_ipv4 @expand_ipv4 @short_ipv4_rev @expand_ipv4_rev @expand_ipv6_rev
	@to_ipv6 @to_ipv6_rev @to_ipv4 @to_ipv4_rev @to_ipv6ipv4 @to_ipv6ipv4_rev
	@format_ipv4 @format_ipv4_rev @format_ipv6 @format_ipv6_rev @ipv4_equal
	@ipv4_not_equal @ipv6_equal @ipv6_not_equal @ipv6ipv4_equal
	@ipv6ipv4_not_equal @wrong_ipv6ipv4 @wrong_ip_net @wrong_net
	@ipv4_in_range @ipv4_not_in_range @ipv6_in_range @ipv6_not_in_range
);

use constant LOCALHOSTIPV4     => '01111111000000000000000000000001';
use constant LOCALHOSTIPV6     => '0' x 127 . '1';
use constant LOCALHOSTIPV6IPV4 => '0' x 80 . '1' x 16 . LOCALHOSTIPV4;
use constant ZERONETIPV4       => '0' x 32;
use constant ZERONETIPV6       => '0' x 128;
use constant UNICASTIPV6       => '11111100' . '0' x 120;
use constant FFFFFFFF0001      => '1' x 32 . '0' x 95 . '1';

our @invalid_addr = (
	[undef,  'undefined value' ],
	[ '',    'empty value' ],
	[ ' ',   'whitespace value' ],
	[ ' ',   'string value' ],
);

our @valid_ipv4 = (
	[ '127.0.1',      LOCALHOSTIPV4 ],
	[ '127.0.1',      LOCALHOSTIPV4 ],
	[ '127.0.0.1',    LOCALHOSTIPV4 ],
	[ 2130706433,     LOCALHOSTIPV4 ],
	[ '017700000001', LOCALHOSTIPV4 ],
	[ '0x7F000001',   LOCALHOSTIPV4 ],
	[ '0177.0.0.1',   LOCALHOSTIPV4 ],
	[ '0X7f.0.0.01',  LOCALHOSTIPV4 ],
	[ '0.0.0.0',      ZERONETIPV4] ,
	[ '0',            ZERONETIPV4 ],
	[ '0x0',          ZERONETIPV4 ],
	[ '0.0',          ZERONETIPV4 ],
);

our @invalid_ipv4 = (
	[ '127.0.0.1.1' ],
	[ 68719476721 ],
	[ '0777777777761' ],
	[ '0xFFFFFFFF1' ],
	[ '127.0.0.256' ],
	[ ' 127.0.0.1' ],
	[ '127.0.0.1 ' ],
	[ '127.0.0.068719476721' ],
	[ '127.0.0.0xFFFFFFFF1' ],
	[ '127.0.a.1' ],
	[ '127.' ],
	[ '.0' ],
	[ '.' ],
	[ '..' ],
); 

our @valid_ipv6 = (
	[ '0:0:0:0:0:0:0:1',        LOCALHOSTIPV6 ],
	[ 'fc00:0:0:0:0:0:0::',     UNICASTIPV6   ],
	[ '::0:0:0:0:0:0:1',        LOCALHOSTIPV6 ],
	[ '0:00:000:00000:0:0:0:1', LOCALHOSTIPV6 ],
	[ '::1',                    LOCALHOSTIPV6 ],
	[ '0:0:0::1',               LOCALHOSTIPV6 ],
	[ '::',                     ZERONETIPV6   ],
	[ 'fc00::',                 UNICASTIPV6   ],
	[ 'ffFF:FFff::0:0:0:1',     FFFFFFFF0001  ],
);

our @invalid_ipv6 = (
	[ '1:' ],
	[ ':1' ],
	[ '0:0:0:0:0:0:0:1:' ],
	[ ':1:2:3:4:5:6:7:8' ],
	[ '::0:0:0:0:0:0:0:1:' ],
	[ '::0:0:0:0:0:0:1:' ],
	[ ':1:2:3:4:5:6:' ],
	[ ':1:2:3:4:5:6:7:' ],
	[ ':1:2:3:4:5:6:7:8:' ],
	[ ':1:2:3:4:5:6:7:8' ],
	[ ':1:2:3:4:5:6:7:8::' ],
	[ ':1:2:3:4:5:6:7::' ],
	[ '0::0:0:0:0:0:0:0' ],
	[ '0:0:0:0: 0:0:0:1' ],
	[ '0:00::0:0::0:1' ],
	[ ':::' ],
	[ ':::1' ],
	[ '::1::' ],
	[ '1:::' ],
	[ ':::1:' ],
	[ ':1:::' ],
	[ ':::1:' ],
	[ ':1:::' ],
	[ ' ::1' ],
	[ '::1 ' ],
	[ '1:::1' ],
	[ '0:0:0:ffff:FFFFFFFF1' ],
	[ '2:0:0:ffff:0:0:1' ],
);

our @valid_ipv6_ipv4 = (
	[ '::ffff:127.0.0.1',         LOCALHOSTIPV6IPV4],
	[ '0:0::ffff:127.0.0.1',      LOCALHOSTIPV6IPV4],
	[ '0:0:0:0:0:ffff:127.0.0.1', LOCALHOSTIPV6IPV4],
);

our @invalid_ipv6_ipv4 = (
	[ '0:0:0:0:ffff:0:127.0.0.1' ],
	[ '0:ffff:127.0.0.1' ],
	[ '0:0:0:0:0:ffff:127.0.0.1.1' ],
	[ '0:0:0:0:0:ffff:127.0.0.256' ],
	[ '0:0:0:0:0:fffff:127.0.0.1' ],
	[ '0:0:0:0:0:fffff:127.0.1' ],
	[ '0:0:0:0:0:fffff:.' ],
	[ '0:0:0:0:0:fffff:.1' ],
	[ '0:0:0:0:0:fffff:127.0.0.0x1' ],
	[ '0:0:0:0:0:fffff:test' ],
	[ '0:0:0:0:0:fffff:127.0.0.a' ],
	[ '0:0:0:0:0:0:ffff:127.0.0.1' ],
	[ '0:0:0:0:0:ffff:127.0.0.1:0' ],
	[ '0:0:0:ffff:127.0.0.1:0' ],
	[ '0:0:0:ffff:2130706433' ],
	[ ' ::ffff:127.0.0.1' ],
	[ '::ffff:127.0.0.1 ' ],
);

our @short_ipv6 = (
	[ '0:0:0:0:0:0:0:0',    '::',                 { short_ipv6 => 1 } ],
	[ '1:0:0:0:0:0:0:0',    '1::',                { short_ipv6 => 1 } ],
	[ '0:0:0:0:0:0:0:1',    '::1',                { short_ipv6 => 1 } ],
	[ 'A:0:0:0:0:0:0:F',    'a::f',               { short_ipv6 => 1 } ],
	[ 'A:0:0:a:0:0:0:F',    'a:0:0:a::f',         { short_ipv6 => 1 } ],
	[ 'F:E:Dd:C:A:B:9:8',   'f:e:dd:c:a:b:9:8',   { short_ipv6 => 1 } ],
	[ 'F:E:8000:1:A:B:9:8', 'f:e:8000:1:a:b:9:8', { short_ipv6 => 1 } ],
	[ '71a::0:a:0:0:0:F',   '71a:0:0:a::f',       { short_ipv6 => 1 } ],
	[ 'A::0:a:1:2:3:F',     'a::a:1:2:3:f',       { short_ipv6 => 1 } ],
	[ 'A::a:8000:0:0:F',    'a::a:8000:0:0:f',    { short_ipv6 => 1 } ],
	[ 'A::a:8000:1:0:F',    'a::a:8000:1:0:f',    { short_ipv6 => 1 } ],
	[ 'F:0:0::A',           'f::a',               { short_ipv6 => 1 } ],
	[ '::0:0:1',            '::1',                { short_ipv6 => 1 } ],
	[ '1:0:1::',            '1:0:1::',            { short_ipv6 => 1 } ],
	[ 'F::B123',            'f::b123',            { short_ipv6 => 1 } ],
	[ 'F::0:111B',          'f::111b',            { short_ipv6 => 1 } ],
	[ '::',                 '::',                 { short_ipv6 => 1 } ],
	[ '00000::1',           '::1',                { short_ipv6 => 1 } ],
	[ 'fc00::0',            'fc00::',             { short_ipv6 => 1 } ],
	[ '0000::0:000:01',     '::1',                { short_ipv6 => 1 } ],
	[ '0001:000:01::',      '1:0:1::',            { short_ipv6 => 1 } ],
	[ '0001:000:FF::',      '0001:0000:00ff::',   { short_ipv6 => 1, lead_zeros => 1 } ],
	[ '0000::0:000:01',     '::0001',             { short_ipv6 => 1, lead_zeros => 1 } ],
	[ '0:0:0:0:0:0:0:0',    '::',                 { short_ipv6 => 1, lead_zeros => 1 } ],
	[ '::1',                '::0001',             { short_ipv6 => 1, lead_zeros => 1 } ],
	[ '71a::0:a:0:0:0:F',   '071a:0000:0000:000a::000f', { short_ipv6 => 1, lead_zeros => 1 } ],
	[ '1:2:3:4:5:6:7:8',    '0001:0002:0003:0004:0005:0006:0007:0008', { short_ipv6 => 1, lead_zeros => 1 } ],
);

our @short_ipv6_rev = (
	[ '0:0:0:0:0:0:0:0',    '::',                 { short_ipv6 => 1, reverse => 1 } ],
	[ '1:0:0:0:0:0:0:0',    '::1',                { short_ipv6 => 1, reverse => 1 } ],
	[ '0:0:0:0:0:0:0:1',    '1::',                { short_ipv6 => 1, reverse => 1 } ],
	[ 'A:0:0:0:0:0:0:F',    'f::a',               { short_ipv6 => 1, reverse => 1 } ],
	[ 'A:0:0:a:0:0:0:F',    'f::a:0:0:a',         { short_ipv6 => 1, reverse => 1 } ],
	[ 'F:E:Dd:C:A:B:9:8',   '8:9:b:a:c:dd:e:f',   { short_ipv6 => 1, reverse => 1 } ],
	[ 'F:E:8000:1:A:B:9:8', '8:9:b:a:1:8000:e:f', { short_ipv6 => 1, reverse => 1 } ],
	[ '71a::0:a:0:0:0:F',   'f::a:0:0:71a',       { short_ipv6 => 1, reverse => 1 } ],
	[ 'A::0:a:1:2:3:F',     'f:3:2:1:a::a',       { short_ipv6 => 1, reverse => 1 } ],
	[ 'A::a:8000:0:0:F',    'f::8000:a:0:0:a',    { short_ipv6 => 1, reverse => 1 } ],
	[ 'A::a:8000:1:0:F',    'f:0:1:8000:a::a',    { short_ipv6 => 1, reverse => 1 } ],
	[ 'F:0:0::A',           'a::f',               { short_ipv6 => 1, reverse => 1 } ],
	[ '::0:0:1',            '1::',                { short_ipv6 => 1, reverse => 1 } ],
	[ '1:0:1::',            '::1:0:1',            { short_ipv6 => 1, reverse => 1 } ],
	[ 'F::B123',            'b123::f',            { short_ipv6 => 1, reverse => 1 } ],
	[ 'F::0:111B',          '111b::f',            { short_ipv6 => 1, reverse => 1 } ],
	[ '::',                 '::',                 { short_ipv6 => 1, reverse => 1 } ],
	[ '00000::1',           '1::',                { short_ipv6 => 1, reverse => 1 } ],
	[ 'fc00::0',            '::fc00',             { short_ipv6 => 1, reverse => 1 } ],
	[ '0000::0:000:01',     '1::',                { short_ipv6 => 1, reverse => 1 } ],
	[ '0001:000:01::',      '::1:0:1',            { short_ipv6 => 1, reverse => 1 } ],
	[ '0001:000:FF::',      '::00ff:0000:0001',   { short_ipv6 => 1, lead_zeros => 1, reverse => 1 } ],
	[ '0000::0:000:01',     '0001::',             { short_ipv6 => 1, lead_zeros => 1, reverse => 1 } ],
	[ '0:0:0:0:0:0:0:0',    '::',                 { short_ipv6 => 1, lead_zeros => 1, reverse => 1 } ],
	[ '::1',                '0001::',             { short_ipv6 => 1, lead_zeros => 1, reverse => 1 } ],
	[ '71a::0:a:0:0:0:F',   '000f::000a:0000:0000:071a', { short_ipv6 => 1, lead_zeros => 1, reverse => 1 } ],
	[ '1:2:3:4:5:6:7:8',    '0008:0007:0006:0005:0004:0003:0002:0001', { short_ipv6 => 1, lead_zeros => 1, reverse => 1 } ],
);

our @expand_ipv6 = (
	[ '::',               '0:0:0:0:0:0:0:0' ],
	[ '0:0::',            '0:0:0:0:0:0:0:0' ],
	[ '::1',              '0:0:0:0:0:0:0:1' ],
	[ '::0:0:1',          '0:0:0:0:0:0:0:1' ],
	[ 'F:0:0:0:0:0:0:F',  'f:0:0:0:0:0:0:f' ],
	[ 'F:0:0::F',         'f:0:0:0:0:0:0:f' ],
	[ '1:0:1::',          '1:0:1:0:0:0:0:0' ],
	[ 'A::a:8000:1:0:F',  'a:0:0:a:8000:1:0:f' ],
	[ 'F::F',             'f:0:0:0:0:0:0:f' ],
	[ 'F::0:111B',        'f:0:0:0:0:0:0:111b' ],
	[ '00000::1',         '0:0:0:0:0:0:0:1' ],
	[ '0001:000:FF::',    '0001:0000:00ff:0000:0000:0000:0000:0000', { lead_zeros => 1 } ],
	[ '0001:000:FF::ff',  '0001:0000:00ff:0000:0000:0000:0000:00ff', { lead_zeros => 1 } ],
	[ '0000::0:000:01',   '0000:0000:0000:0000:0000:0000:0000:0001', { lead_zeros => 1 } ],
	[ '0:0:0:0:0:0:0:0',  '0000:0000:0000:0000:0000:0000:0000:0000', { lead_zeros => 1 } ],
	[ '1:2:3:4:5:6:7:88', '0001:0002:0003:0004:0005:0006:0007:0088', { lead_zeros => 1 } ],
	[ '::1',              '0000:0000:0000:0000:0000:0000:0000:0001', { lead_zeros => 1 } ],
);

our @expand_ipv6_rev = (
	[ '::',               '0:0:0:0:0:0:0:0',    { reverse => 1 } ],
	[ '0:0::',            '0:0:0:0:0:0:0:0',    { reverse => 1 } ],
	[ '::1',              '1:0:0:0:0:0:0:0',    { reverse => 1 } ],
	[ '::0:0:1',          '1:0:0:0:0:0:0:0',    { reverse => 1 } ],
	[ 'F:0:0:0:0:0:0:F',  'f:0:0:0:0:0:0:f',    { reverse => 1 } ],
	[ 'F:0:0::F',         'f:0:0:0:0:0:0:f',    { reverse => 1 } ],
	[ '1:0:1::',          '0:0:0:0:0:1:0:1',    { reverse => 1 } ],
	[ 'A::a:8000:1:0:F',  'f:0:1:8000:a:0:0:a', { reverse => 1 } ],
	[ 'F::F',             'f:0:0:0:0:0:0:f',    { reverse => 1 } ],
	[ 'F::0:111B',        '111b:0:0:0:0:0:0:f', { reverse => 1 } ],
	[ '00000::1',         '1:0:0:0:0:0:0:0',    { reverse => 1 } ],
	[ '0001:000:FF::',    '0000:0000:0000:0000:0000:00ff:0000:0001', { lead_zeros => 1, reverse => 1 } ],
	[ '0001:000:FF::ff',  '00ff:0000:0000:0000:0000:00ff:0000:0001', { lead_zeros => 1, reverse => 1 } ],
	[ '0000::0:000:01',   '0001:0000:0000:0000:0000:0000:0000:0000', { lead_zeros => 1, reverse => 1 } ],
	[ '0:0:0:0:0:0:0:0',  '0000:0000:0000:0000:0000:0000:0000:0000', { lead_zeros => 1, reverse => 1 } ],
	[ '1:2:3:4:5:6:7:88', '0088:0007:0006:0005:0004:0003:0002:0001', { lead_zeros => 1, reverse => 1 } ],
	[ '::1',              '0001:0000:0000:0000:0000:0000:0000:0000', { lead_zeros => 1, reverse => 1 } ],
);

our @short_ipv4 = (
	[ '0.0.0.0',          '0.0',         { short_ipv4 => 1 } ],
	[ '127.0.0.1',        '127.1',       { short_ipv4 => 1 } ],
	[ '127.00000.0000.1', '127.1',       { short_ipv4 => 1 } ],
	[ '192.168.0.1',      '192.168.1',   { short_ipv4 => 1 } ],
	[ '192.0.168.1',      '192.0.168.1', { short_ipv4 => 1 } ],
	[ '0.0.0.1',          '0.1',         { short_ipv4 => 1 } ],
	[ '1.0.0.0',          '1.0',         { short_ipv4 => 1 } ],
	[ '1.2',              '1.2',         { short_ipv4 => 1 } ],
	[ '1.0.0xaa',         '1.170',       { short_ipv4 => 1 } ],
	[ '1.15.17.25',       '1.15.17.25',  { short_ipv4 => 1 } ],
);

our @short_ipv4_rev = (
	[ '0.0.0.0',          '0.0',         { short_ipv4 => 1, reverse => 1 } ],
	[ '127.0.0.1',        '1.127',       { short_ipv4 => 1, reverse => 1 } ],
	[ '127.00000.0000.1', '1.127',       { short_ipv4 => 1, reverse => 1 } ],
	[ '192.168.0.1',      '1.0.168.192', { short_ipv4 => 1, reverse => 1 } ],
	[ '192.0.168.1',      '1.168.192',   { short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.1',          '1.0',         { short_ipv4 => 1, reverse => 1 } ],
	[ '1.0.0.0',          '0.1',         { short_ipv4 => 1, reverse => 1 } ],
	[ '1.2',              '2.1',         { short_ipv4 => 1, reverse => 1 } ],
	[ '1.0.0xaa',         '170.1',       { short_ipv4 => 1, reverse => 1 } ],
	[ '0177.0.0xaa',      '170.127',     { short_ipv4 => 1, reverse => 1 } ],
	[ '1.15.17.25',       '25.17.15.1',  { short_ipv4 => 1, reverse => 1 } ],
);

our @expand_ipv4 = (
	[ '0.0.0.0',          '0.0.0.0' ],
	[ '127.0.0.1',        '127.0.0.1' ],
	[ '127.00000.0000.1', '127.0.0.1' ],
	[ '192.168.1',        '192.168.0.1' ],
	[ '127.1',            '127.0.0.1' ],
	[ '0.1',              '0.0.0.1' ],
	[ '1.0.0',            '1.0.0.0' ],
	[ '0.0',              '0.0.0.0' ],
	[ '0.0.0',            '0.0.0.0' ],
	[ '1.2',              '1.0.0.2' ],
	[ '1.0.0xaa',         '1.0.0.170' ],
	[ '0177.0.0xaa',      '127.0.0.170' ],
	[ '1.15.17.25',       '1.15.17.25' ],
);

our @expand_ipv4_rev = (
	[ '0.0.0.0',          '0.0.0.0',     { reverse => 1 } ],
	[ '127.0.0.1',        '1.0.0.127',   { reverse => 1 } ],
	[ '127.00000.0000.1', '1.0.0.127',   { reverse => 1 } ],
	[ '192.168.1',        '1.0.168.192', { reverse => 1 } ],
	[ '127.1',            '1.0.0.127',   { reverse => 1 } ],
	[ '0.1',              '1.0.0.0',     { reverse => 1 } ],
	[ '1.0.0',            '0.0.0.1',     { reverse => 1 } ],
	[ '0.0',              '0.0.0.0',     { reverse => 1 } ],
	[ '0.0.0',            '0.0.0.0',     { reverse => 1 } ],
	[ '1.2',              '2.0.0.1',     { reverse => 1 } ],
	[ '1.0.0xaa',         '170.0.0.1',   { reverse => 1 } ],
	[ '0177.0.0xaa',      '170.0.0.127', { reverse => 1 } ],
	[ '1.15.17.25',       '25.17.15.1',  { reverse => 1 } ],
);

our @to_ipv6 = (
	[ '0.0.0.0',      '::ffff:0:0',                              { convert_to => 'ipv6', short_ipv6 => 1 } ],
	[ '127.0.0.1',    '::ffff:7f00:1',                           { convert_to => 'ipv6', short_ipv6 => 1 } ],
	[ '0.0.0.0',      '0:0:0:0:0:ffff:0:0',                      { convert_to => 'ipv6' } ],
	[ '127.0.0.1',    '0:0:0:0:0:ffff:7f00:1',                   { convert_to => 'ipv6' } ],
	[ '0.0.0.0',      '::ffff:0000:0000',                        { convert_to => 'ipv6', short_ipv6 => 1, lead_zeros => 1 } ],
	[ '127.65.160.1', '::ffff:7f41:a001',                        { convert_to => 'ipv6', short_ipv6 => 1, lead_zeros => 1 } ],
	[ '0.0.0.0',      '0000:0000:0000:0000:0000:ffff:0000:0000', { convert_to => 'ipv6', lead_zeros => 1 } ],
	[ '127.0.1.1',    '0000:0000:0000:0000:0000:ffff:7f00:0101', { convert_to => 'ipv6', lead_zeros => 1 } ],
	[ '0.0',          '::ffff:0:0',                              { convert_to => 'ipv6', short_ipv6 => 1 } ],
	[ '127.0.1',      '::ffff:7f00:1',                           { convert_to => 'ipv6', short_ipv6 => 1 } ],
	[ '::00',         '::',                                      { convert_to => 'ipv6', short_ipv6 => 1 } ],
	[ '::1',          '0:0:0:0:0:0:0:1',                         { convert_to => 'ipv6', short_ipv6 => 0 } ],
);

our @to_ipv6_rev = (
	[ '0.0.0.0',      '0:0:ffff::',                              { convert_to => 'ipv6', short_ipv6 => 1, reverse => 1 } ],
	[ '127.0.0.1',    '1:7f00:ffff::',                           { convert_to => 'ipv6', short_ipv6 => 1, reverse => 1 } ],
	[ '0.0.0.0',      '0:0:ffff:0:0:0:0:0',                      { convert_to => 'ipv6', reverse => 1 } ],
	[ '127.0.0.1',    '1:7f00:ffff:0:0:0:0:0',                   { convert_to => 'ipv6', reverse => 1 } ],
	[ '0.0.0.0',      '0000:0000:ffff::',                        { convert_to => 'ipv6', short_ipv6 => 1, lead_zeros => 1, reverse => 1 } ],
	[ '127.65.160.1', 'a001:7f41:ffff::',                        { convert_to => 'ipv6', short_ipv6 => 1, lead_zeros => 1, reverse => 1 } ],
	[ '0.0.0.0',      '0000:0000:ffff:0000:0000:0000:0000:0000', { convert_to => 'ipv6', lead_zeros => 1, reverse => 1 } ],
	[ '127.0.1.1',    '0101:7f00:ffff:0000:0000:0000:0000:0000', { convert_to => 'ipv6', lead_zeros => 1, reverse => 1 } ],
	[ '0.0',          '0:0:ffff::',                              { convert_to => 'ipv6', short_ipv6 => 1, reverse => 1 } ],
	[ '127.0.1',      '1:7f00:ffff::',                           { convert_to => 'ipv6', short_ipv6 => 1, reverse => 1 } ],
	[ '::00',         '::',                                      { convert_to => 'ipv6', short_ipv6 => 1, reverse => 1 } ],
[ '::1',          '1:0:0:0:0:0:0:0',                         { convert_to => 'ipv6', short_ipv6 => 0, reverse => 1 } ],
);

our @to_ipv4 = (
	[ '::ffff:0:0',                              '0.0',             { convert_to => 'ipv4', short_ipv4 => 1 } ],
	[ '::ffff:7f00:1',                           '127.1',           { convert_to => 'ipv4', short_ipv4 => 1 } ],
	[ '0:0:0:0:0:ffff:0:0',                      '0.0.0.0',         { convert_to => 'ipv4' } ],
	[ '0:0:0:0:0:ffff:7f01:1',                   '127.1.0.1',       { convert_to => 'ipv4' } ],
	[ '::ffff:0000:0000',                        '0.0',             { convert_to => 'ipv4', short_ipv4 => 1 } ],
	[ '::ffff:7f00:0001',                        '127.1',           { convert_to => 'ipv4', short_ipv4 => 1 } ],
	[ '0000:0000:0000:0000:0000:ffff:0000:0000', '0.0.0.0',         { convert_to => 'ipv4' } ],
	[ '0000:0000:0000:0000:0000:ffff:7fff:0001', '127.255.0.1',     { convert_to => 'ipv4' } ],
	[ '::ffff:0:0',                              '0.0',             { convert_to => 'ipv4', short_ipv4 => 1 } ],
	[ '::',                                      '0:0:0:0:0:0:0:0', { convert_to => 'ipv4' } ],
	[ '0:0:0:0:0:0:0:1',                         '::1',             { convert_to => 'ipv4', short_ipv6 => 1 } ],
	[ '0.0.0.0',                                 '0.0.0.0',         { convert_to => 'ipv4', short_ipv6 => 1 } ],
	[ '127.5.44.1',                              '127.5.44.1',      { convert_to => 'ipv4', short_ipv6 => 0 } ],
	[ '0.0.0.0',                                 '0.0',             { convert_to => 'ipv4', short_ipv4 => 1 } ],
	[ '127.0.0.1',                               '127.1',           { convert_to => 'ipv4', short_ipv4 => 1 } ],
);

our @to_ipv4_rev = (
	[ '::ffff:0:0',                              '0.0',             { convert_to => 'ipv4', short_ipv4 => 1, reverse => 1 } ],
	[ '::ffff:7f00:1',                           '1.127',           { convert_to => 'ipv4', short_ipv4 => 1, reverse => 1 } ],
	[ '0:0:0:0:0:ffff:0:0',                      '0.0.0.0',         { convert_to => 'ipv4', reverse => 1 } ],
	[ '0:0:0:0:0:ffff:7f01:1',                   '1.0.1.127',       { convert_to => 'ipv4', reverse => 1 } ],
	[ '::ffff:0000:0000',                        '0.0',             { convert_to => 'ipv4', short_ipv4 => 1, reverse => 1 } ],
	[ '::ffff:7f00:0001',                        '1.127',           { convert_to => 'ipv4', short_ipv4 => 1, reverse => 1 } ],
	[ '0000:0000:0000:0000:0000:ffff:0000:0000', '0.0.0.0',         { convert_to => 'ipv4', reverse => 1 } ],
	[ '0000:0000:0000:0000:0000:ffff:7fff:0001', '1.0.255.127',     { convert_to => 'ipv4', reverse => 1 } ],
	[ '::ffff:0:0',                              '0.0',             { convert_to => 'ipv4', short_ipv4 => 1, reverse => 1 } ],
	[ '::',                                      '0:0:0:0:0:0:0:0', { convert_to => 'ipv4', reverse => 1 } ],
	[ '0:0:0:0:0:0:0:1',                         '1::',             { convert_to => 'ipv4', short_ipv6 => 1, reverse => 1 } ],
	[ '0.0.0.0',                                 '0.0.0.0',         { convert_to => 'ipv4', short_ipv6 => 1, reverse => 1 } ],
	[ '127.5.44.1',                              '1.44.5.127',      { convert_to => 'ipv4', short_ipv6 => 0, reverse => 1 } ],
	[ '0.0.0.0',                                 '0.0',             { convert_to => 'ipv4', short_ipv4 => 1, reverse => 1 } ],
	[ '127.0.0.1',                               '1.127',           { convert_to => 'ipv4', short_ipv4 => 1, reverse => 1 } ],
);

our @to_ipv6ipv4 = (
	[ '::ffff:0:0',                  '::ffff:0.0.0.0',                            { convert_to => 'ipv6ipv4', short_ipv4 => 1, short_ipv6 => 1 } ],
	[ '::ffff:7f00:1',               '::ffff:127.0.0.1',                          { convert_to => 'ipv6ipv4', short_ipv4 => 1, short_ipv6 => 1 } ],
	[ '0:0:0:0:0:ffff:0:0',          '0:0:0:0:0:ffff:0.0.0.0',                    { convert_to => 'ipv6ipv4' } ],
	[ '0:0:0:0:0:ffff:7f00:1',       '0:0:0:0:0:ffff:127.0.0.1',                  { convert_to => 'ipv6ipv4' } ],
	[ '0:0:0:0:0:ffff:0:0',          '0000:0000:0000:0000:0000:ffff:0.0.0.0',     { convert_to => 'ipv6ipv4', lead_zeros => 1 } ],
	[ '0:0:0:0:0:ffff:7fab:1',       '0000:0000:0000:0000:0000:ffff:127.171.0.1', { convert_to => 'ipv6ipv4', lead_zeros => 1 } ],
	[ '::1',                         '0000:0000:0000:0000:0000:0000:0000:0001',   { convert_to => 'ipv6ipv4', lead_zeros => 1 } ],
	[ '::1',                         '0:0:0:0:0:0:0:1',                           { convert_to => 'ipv6ipv4', } ],
	[ '0:00::0:1',                   '::1',                                       { convert_to => 'ipv6ipv4', short_ipv6 => 1 } ],
	[ '127.0.0.1',                   '::ffff:127.0.0.1',                          { convert_to => 'ipv6ipv4', short_ipv6 => 1, short_ipv4 => 1 } ],
	[ '0.0',                         '0:0:0:0:0:ffff:0.0.0.0',                    { convert_to => 'ipv6ipv4', short_ipv4 => 1 } ],
	[ '5.0',                         '::ffff:5.0.0.0',                            { convert_to => 'ipv6ipv4', short_ipv6 => 1 } ],
	[ '127.0.1',                     '0000:0000:0000:0000:0000:ffff:127.0.0.1',   { convert_to => 'ipv6ipv4', lead_zeros => 1, short_ipv4 => 1 } ],
);

our @to_ipv6ipv4_rev = (
	[ '::ffff:0:0',                  '::ffff:0.0.0.0',                            { convert_to => 'ipv6ipv4', short_ipv4 => 1, short_ipv6 => 1, reverse => 1 } ],
	[ '::ffff:7f00:1',               '::ffff:1.0.0.127',                          { convert_to => 'ipv6ipv4', short_ipv4 => 1, short_ipv6 => 1, reverse => 1 } ],
	[ '0:0:0:0:0:ffff:0:0',          '0:0:0:0:0:ffff:0.0.0.0',                    { convert_to => 'ipv6ipv4', reverse => 1 } ],
	[ '0:0:0:0:0:ffff:7f00:1',       '0:0:0:0:0:ffff:1.0.0.127',                  { convert_to => 'ipv6ipv4', reverse => 1 } ],
	[ '0:0:0:0:0:ffff:0:0',          '0000:0000:0000:0000:0000:ffff:0.0.0.0',     { convert_to => 'ipv6ipv4', lead_zeros => 1, reverse => 1 } ],
	[ '0:0:0:0:0:ffff:7fab:1',       '0000:0000:0000:0000:0000:ffff:1.0.171.127', { convert_to => 'ipv6ipv4', lead_zeros => 1, reverse => 1 } ],
	[ '::1',                         '0001:0000:0000:0000:0000:0000:0000:0000',   { convert_to => 'ipv6ipv4', lead_zeros => 1, reverse => 1 } ],
	[ '::1',                         '1:0:0:0:0:0:0:0',                           { convert_to => 'ipv6ipv4', reverse => 1 } ],
	[ '0:00::0:1',                   '1::',                                       { convert_to => 'ipv6ipv4', short_ipv6 => 1, reverse => 1 } ],
	[ '127.0.0.1',                   '::ffff:1.0.0.127',                          { convert_to => 'ipv6ipv4', short_ipv6 => 1, short_ipv4 => 1, reverse => 1 } ],
	[ '0.0',                         '0:0:0:0:0:ffff:0.0.0.0',                    { convert_to => 'ipv6ipv4', short_ipv4 => 1, reverse => 1 } ],
	[ '0.5',                         '::ffff:5.0.0.0',                            { convert_to => 'ipv6ipv4', short_ipv6 => 1, reverse => 1 } ],
	[ '127.0.1',                     '0000:0000:0000:0000:0000:ffff:1.0.0.127',   { convert_to => 'ipv6ipv4', lead_zeros => 1, short_ipv4 => 1, reverse => 1 } ],
);

our @format_ipv4 = (
	[ '127.0.0.1',          '0x7f000001',          { format_ipv4 => 'X' } ],
	[ '127.0.0.1',          '2130706433',          { format_ipv4 => 'D' } ],
	[ '127.0.0.1',          '017700000001',        { format_ipv4 => 'O' } ],

	[ '0xff.255.0377.0xff', '0xffffffff',          { format_ipv4 => 'X' } ],
	[ '0xff.255.0377.0xff', '4294967295',          { format_ipv4 => 'D' } ],
	[ '255.255.255.255',    '037777777777',        { format_ipv4 => 'O' } ],

	[ '0.0.0.0',            '0x0',                 { format_ipv4 => 'X' } ],
	[ '0.0.0.0',            '0',                   { format_ipv4 => 'D' } ],
	[ '0.0.0.0',            '0',                   { format_ipv4 => 'O' } ],

	[ '0.0.0.1',            '0x1',                 { format_ipv4 => 'X' } ],
	[ '0.0.0.1',            '1',                   { format_ipv4 => 'D' } ],
	[ '0.0.0.1',            '01',                  { format_ipv4 => 'O' } ],

	[ '109.172.72.82',      '0x6dac4852',          { format_ipv4 => 'X' } ],
	[ '217.45.0.4',         '3643604996',          { format_ipv4 => 'D' } ],
	[ '8.40.120.7',         '01012074007',         { format_ipv4 => 'O' } ],
	[ '239.19.34.3',        '0xef.0x13.0x22.0x3',  { format_ipv4 => 'x' } ],
	[ '212.17.50.2',        '212.17.50.2',         { } ],
	[ '10.3.40.86',         '012.03.050.0126',     { format_ipv4 => 'o' } ],

	[ '0.0.0.23',           '027',                 { format_ipv4 => 'O' } ],
	[ '0.0.0.0',            '0x00000000',          { format_ipv4 => 'X', lead_zeros => 1 } ],
	[ '0.0.0.0xff',         '0x000000ff',          { format_ipv4 => 'X', lead_zeros => 1 } ],

	[ '127.0.0.1',          '0x7f.0x0.0x0.0x1',    { format_ipv4 => 'x' } ],
	[ '127.0.0.1',          '127.0.0.1',           { format_ipv4 => 'd' } ],
	[ '127.0.0.1',          '0177.0.0.01',         { format_ipv4 => 'o' } ],

	[ '0xff.255.0377.0xff', '0xff.0xff.0xff.0xff', { format_ipv4 => 'x' } ],
	[ '0xff.255.0377.0xff', '255.255.255.255',     { } ],
	[ '255.255.255.255',    '0377.0377.0377.0377', { format_ipv4 => 'o' } ],

	[ '0.0.0.0',            '0x0.0x0.0x0.0x0',     { format_ipv4 => 'x' } ],
	[ '0.0.0.0',            '0.0.0.0',             { format_ipv4 => 'd' } ],
	[ '0.0.0.0',            '0.0.0.0',             { format_ipv4 => 'o' } ],

	[ '0.0.0.1',            '0x0.0x0.0x0.0x1',     { format_ipv4 => 'x' } ],
	[ '0.0.0.1',            '0.0.0.1',             { } ],
	[ '0.0.0.1',            '0.0.0.01',            { format_ipv4 => 'o' } ],

	[ '0.0.0.23',           '0.0.0.027',           { format_ipv4 => 'o' } ],
	[ '0.0.0.0',            '0x00.0x00.0x00.0x00', { format_ipv4 => 'x', lead_zeros => 1 } ],
	[ '0.1.0.0xff',         '0x00.0x01.0x00.0xff', { format_ipv4 => 'x', lead_zeros => 1 } ],

	[ '127.0.0.1',          '0x7f.0x1',            { format_ipv4 => 'x', short_ipv4 => 1 } ],
	[ '127.0.0.1',          '127.1',               { format_ipv4 => 'd', short_ipv4 => 1 } ],
	[ '127.0.0.1',          '0177.01',             { format_ipv4 => 'o', short_ipv4 => 1 } ],

	[ '0.0.0.0',            '0x0.0x0',             { format_ipv4 => 'x', short_ipv4 => 1 } ],
	[ '0.0.0.0',            '0.0',                 { format_ipv4 => 'd', short_ipv4 => 1 } ],
	[ '0.0.0.0',            '0.0',                 { format_ipv4 => 'o', short_ipv4 => 1 } ],

	[ '0.0.0.1',            '0x0.0x1',             { format_ipv4 => 'x', short_ipv4 => 1 } ],
	[ '0.0.0.1',            '0.1',                 {                     short_ipv4 => 1 } ],
	[ '0.0.0.1',            '0.01',                { format_ipv4 => 'o', short_ipv4 => 1 } ],
	[ '0.0.0.23',           '0.027',               { format_ipv4 => 'o', short_ipv4 => 1 } ],
	[ '0.0.0.0',            '0x00.0x00',           { format_ipv4 => 'x', short_ipv4 => 1, lead_zeros => 1 } ],
	[ '0.1.0.0xff',         '0x00.0x01.0xff',      { format_ipv4 => 'x', short_ipv4 => 1, lead_zeros => 1 } ],
);

our @format_ipv4_rev = (
	[ '127.0.0.1',          '0x100007f',           { format_ipv4 => 'X', reverse => 1 } ],
	[ '127.0.0.1',          '16777343',            { format_ipv4 => 'D', reverse => 1 } ],
	[ '127.0.0.1',          '0100000177',          { format_ipv4 => 'O', reverse => 1 } ],

	[ '0xff.255.0377.0xff', '0xffffffff',          { format_ipv4 => 'X', reverse => 1 } ],
	[ '0xff.255.0377.0xff', '4294967295',          { format_ipv4 => 'D', reverse => 1 } ],
	[ '255.255.255.255',    '037777777777',        { format_ipv4 => 'O', reverse => 1 } ],

	[ '0.0.0.0',            '0x0',                 { format_ipv4 => 'X', reverse => 1 } ],
	[ '0.0.0.0',            '0',                   { format_ipv4 => 'D', reverse => 1 } ],
	[ '0.0.0.0',            '0',                   { format_ipv4 => 'O', reverse => 1 } ],

	[ '0.0.0.1',            '0x1000000',           { format_ipv4 => 'X', reverse => 1 } ],
	[ '0.0.0.1',            '16777216',            { format_ipv4 => 'D', reverse => 1 } ],
	[ '0.0.0.1',            '0100000000',          { format_ipv4 => 'O', reverse => 1 } ],

	[ '109.172.72.82',      '0x5248ac6d',          { format_ipv4 => 'X', reverse => 1 } ],
	[ '217.45.0.4',         '67120601',            { format_ipv4 => 'D', reverse => 1 } ],
	[ '8.40.120.7',         '0736024010',          { format_ipv4 => 'O', reverse => 1 } ],
	[ '239.19.34.3',        '0x3.0x22.0x13.0xef',  { format_ipv4 => 'x', reverse => 1 } ],
	[ '212.17.50.2',        '2.50.17.212',         { reverse => 1} ],
	[ '10.3.40.86',         '0126.050.03.012',     { format_ipv4 => 'o', reverse => 1 } ],

	[ '0.0.0.23',           '02700000000',         { format_ipv4 => 'O', reverse => 1 } ],
	[ '0.0.0.0',            '0x00000000',          { format_ipv4 => 'X', lead_zeros => 1, reverse => 1 } ],
	[ '0.0.0.0xff',         '0xff000000',          { format_ipv4 => 'X', lead_zeros => 1, reverse => 1 } ],

	[ '127.0.0.1',          '0x1.0x0.0x0.0x7f',    { format_ipv4 => 'x', reverse => 1 } ],
	[ '127.0.0.1',          '1.0.0.127',           { format_ipv4 => 'd', reverse => 1 } ],
	[ '127.0.0.1',          '01.0.0.0177',         { format_ipv4 => 'o', reverse => 1 } ],

	[ '0xff.255.0377.0xff', '0xff.0xff.0xff.0xff', { format_ipv4 => 'x', reverse => 1 } ],
	[ '0xff.255.0377.0xff', '255.255.255.255',     { reverse => 1 } ],
	[ '255.255.255.255',    '0377.0377.0377.0377', { format_ipv4 => 'o', reverse => 1 } ],

	[ '0.0.0.0',            '0x0.0x0.0x0.0x0',     { format_ipv4 => 'x', reverse => 1 } ],
	[ '0.0.0.0',            '0.0.0.0',             { format_ipv4 => 'd', reverse => 1 } ],
	[ '0.0.0.0',            '0.0.0.0',             { format_ipv4 => 'o', reverse => 1 } ],

	[ '0.0.0.1',            '0x1.0x0.0x0.0x0',     { format_ipv4 => 'x', reverse => 1 } ],
	[ '0.0.0.1',            '1.0.0.0',             { reverse => 1 	} ],
	[ '0.0.0.1',            '01.0.0.0',            { format_ipv4 => 'o', reverse => 1 } ],

	[ '0.0.0.23',           '027.0.0.0',           { format_ipv4 => 'o', reverse => 1 } ],
	[ '0.0.0.0',            '0x00.0x00.0x00.0x00', { format_ipv4 => 'x', lead_zeros => 1, reverse => 1 } ],
	[ '0.1.0.0xff',         '0xff.0x00.0x01.0x00', { format_ipv4 => 'x', lead_zeros => 1, reverse => 1 } ],

	[ '127.0.0.1',          '0x1.0x7f',            { format_ipv4 => 'x', short_ipv4 => 1, reverse => 1 } ],
	[ '127.0.0.1',          '1.127',               { format_ipv4 => 'd', short_ipv4 => 1, reverse => 1 } ],
	[ '127.0.0.1',          '01.0177',             { format_ipv4 => 'o', short_ipv4 => 1, reverse => 1 } ],

	[ '0.0.0.0',            '0x0.0x0',             { format_ipv4 => 'x', short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.0',            '0.0',                 { format_ipv4 => 'd', short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.0',            '0.0',                 { format_ipv4 => 'o', short_ipv4 => 1, reverse => 1 } ],

	[ '0.0.0.1',            '0x1.0x0',             { format_ipv4 => 'x', short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.1',            '1.0',                 {                     short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.1',            '01.0',                { format_ipv4 => 'o', short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.23',           '027.0',               { format_ipv4 => 'o', short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.0',            '0x00.0x00',           { format_ipv4 => 'x', short_ipv4 => 1, lead_zeros => 1, reverse => 1 } ],
	[ '0.1.0.0xff',         '0xff.0x00.0x01.0x00', { format_ipv4 => 'x', short_ipv4 => 1, lead_zeros => 1, reverse => 1 } ],
);

our @format_ipv6 = (
	[ '0.0.0.0',            '::ffff:0:0',                              { convert_to => 'ipv6', format_ipv4 => 'X', short_ipv6 => 1 } ],
	[ '0.0.0.0xff',         '::ffff:0000:00ff',                        { convert_to => 'ipv6', format_ipv4 => 'x', short_ipv6 => 1, lead_zeros => 1 } ],
	[ '0.0.0.0',            '0000:0000:0000:0000:0000:ffff:0000:0000', { convert_to => 'ipv6', format_ipv4 => 'O', lead_zeros => 1} ],
	[ '0.0.0.0xff',         '0:0:0:0:0:ffff:0:ff',                     { convert_to => 'ipv6', format_ipv4 => 'o' } ],
	[ '0.0.0.0',            '::ffff:0:0',                              { convert_to => 'ipv6', format_ipv4 => 'X', short_ipv6 => 1, short_ipv4 => 1 } ],
	[ '0.0.0.0xff',         '::ffff:0000:00ff',                        { convert_to => 'ipv6', format_ipv4 => 'O', short_ipv6 => 1, lead_zeros => 1, short_ipv4 => 1 } ],
	[ '1.0.0.0',            '0000:0000:0000:0000:0000:ffff:0100:0000', { convert_to => 'ipv6', format_ipv4 => 'x', lead_zeros => 1, short_ipv4 => 1 } ],
	[ '0.0.0.0xff',         '0:0:0:0:0:ffff:0:ff',                     { convert_to => 'ipv6', format_ipv4 => 'o', short_ipv4 => 1 } ],
	[ '217.19.105.124',     '0:0:0:0:0:ffff:d913:697c',                { convert_to => 'ipv6', format_ipv4 => 'X' } ],
	[ '10.77.0.77',         '::ffff:a4d:4d',                           { convert_to => 'ipv6', format_ipv4 => 'o', short_ipv6 => 1 } ],
	[ '0.0.0.0',            '::ffff:0.0.0.0',                          { convert_to => 'ipv6ipv4', format_ipv4 => 'x', short_ipv6 => 1, short_ipv4 => 1 } ],
	[ '0.0.0.0xff',         '::ffff:0.0.0.255',                        { convert_to => 'ipv6ipv4', format_ipv4 => 'o', short_ipv6 => 1, lead_zeros => 1, short_ipv4 => 1 } ],
	[ '0.0.0.1',            '0000:0000:0000:0000:0000:ffff:0.0.0.1',   { convert_to => 'ipv6ipv4', format_ipv4 => 'O', lead_zeros => 1, short_ipv4 => 1 } ],
	[ '0.0.0.0xff',         '0:0:0:0:0:ffff:0.0.0.255',                { convert_to => 'ipv6ipv4', format_ipv4 => 'X', short_ipv4 => 1 } ],
	[ '0.0.0.0',            '::ffff:0.0.0.0',                          { convert_to => 'ipv6ipv4', format_ipv4 => 'O', short_ipv6 => 1, short_ipv4 => 1 } ],
	[ '0.0.0.0xff',         '::ffff:0.0.0.255',                        { convert_to => 'ipv6ipv4', format_ipv4 => 'o', short_ipv6 => 1, lead_zeros => 1 } ],
	[ '0.0.0.1',            '0000:0000:0000:0000:0000:ffff:0.0.0.1',   { convert_to => 'ipv6ipv4', format_ipv4 => 'x', lead_zeros => 1 } ],
	[ '1.0.0.0xff',         '0:0:0:0:0:ffff:1.0.0.255',                { convert_to => 'ipv6ipv4', format_ipv4 => 'X' } ],
	[ '172.17.43.10',       '0:0:0:0:0:ffff:172.17.43.10',             { convert_to => 'ipv6ipv4', format_ipv4 => 'X'} ],
	[ '199.15.176.140',     '::ffff:199.15.176.140',                   { convert_to => 'ipv6ipv4', format_ipv4 => 'o', short_ipv6 => 1 } ],
);

our @format_ipv6_rev = (
	[ '0.0.0.0',            '0:0:ffff::',                              { convert_to => 'ipv6', format_ipv4 => 'X', short_ipv6 => 1, reverse => 1 } ],
	[ '0.0.0.0xff',         '00ff:0000:ffff::',                        { convert_to => 'ipv6', format_ipv4 => 'x', short_ipv6 => 1, reverse => 1, lead_zeros => 1 } ],
	[ '0.0.0.0',            '0000:0000:ffff:0000:0000:0000:0000:0000', { convert_to => 'ipv6', format_ipv4 => 'O', lead_zeros => 1, reverse => 1 } ],
	[ '0.0.0.0xff',         'ff:0:ffff:0:0:0:0:0',                     { convert_to => 'ipv6', format_ipv4 => 'o', reverse => 1 } ],
	[ '0.0.0.0',            '0:0:ffff::',                              { convert_to => 'ipv6', format_ipv4 => 'X', short_ipv6 => 1, short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.0xff',         '00ff:0000:ffff::',                        { convert_to => 'ipv6', format_ipv4 => 'O', short_ipv6 => 1, lead_zeros => 1, short_ipv4 => 1, reverse => 1 } ],
	[ '1.0.0.0',            '0000:0100:ffff:0000:0000:0000:0000:0000', { convert_to => 'ipv6', format_ipv4 => 'x', lead_zeros => 1, short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.0xff',         'ff:0:ffff:0:0:0:0:0',                     { convert_to => 'ipv6', format_ipv4 => 'o', short_ipv4 => 1, reverse => 1 } ],
	[ '217.19.105.124',     '697c:d913:ffff:0:0:0:0:0',                { convert_to => 'ipv6', format_ipv4 => 'X', reverse => 1 } ],
	[ '10.77.0.77',         '4d:a4d:ffff::',                           { convert_to => 'ipv6', format_ipv4 => 'o', short_ipv6 => 1, reverse => 1 } ],
	[ '0.0.0.0',            '::ffff:0.0.0.0',                          { convert_to => 'ipv6ipv4', format_ipv4 => 'x', short_ipv6 => 1, short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.0xff',         '::ffff:255.0.0.0',                        { convert_to => 'ipv6ipv4', format_ipv4 => 'o', short_ipv6 => 1, lead_zeros => 1, short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.1',            '0000:0000:0000:0000:0000:ffff:1.0.0.0',   { convert_to => 'ipv6ipv4', format_ipv4 => 'O', lead_zeros => 1, short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.0xff',         '0:0:0:0:0:ffff:255.0.0.0',                { convert_to => 'ipv6ipv4', format_ipv4 => 'X', short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.0',            '::ffff:0.0.0.0',                          { convert_to => 'ipv6ipv4', format_ipv4 => 'O', short_ipv6 => 1, short_ipv4 => 1, reverse => 1 } ],
	[ '0.0.0.0xff',         '::ffff:255.0.0.0',                        { convert_to => 'ipv6ipv4', format_ipv4 => 'o', short_ipv6 => 1, lead_zeros => 1, reverse => 1 } ],
	[ '0.0.0.1',            '0000:0000:0000:0000:0000:ffff:1.0.0.0',   { convert_to => 'ipv6ipv4', format_ipv4 => 'x', lead_zeros => 1, reverse => 1 } ],
	[ '1.0.0.0xff',         '0:0:0:0:0:ffff:255.0.0.1',                { convert_to => 'ipv6ipv4', format_ipv4 => 'X', reverse => 1 } ],
	[ '172.17.43.10',       '0:0:0:0:0:ffff:10.43.17.172',             { convert_to => 'ipv6ipv4', format_ipv4 => 'X', reverse => 1 } ],
	[ '199.15.176.140',     '::ffff:140.176.15.199',                   { convert_to => 'ipv6ipv4', format_ipv4 => 'o', short_ipv6 => 1, reverse => 1 } ],
);

our @ipv4_equal = (
	[ '127.0.0.1',          '127.0.1' ],
	[ '127.0.0.1',          '127.1' ],
	[ '127.0.0.1',          '0177.0.0.01' ],
	[ '127.0.0.1',          '0x7f.0.0.1' ],
	[ '127.0.0.1',          '0x7f.0.0.0x1' ],
	[ '127.0.0.1',          '0x7f000001' ],
	[ '127.0.0.1',          '017700000001' ],
	[ '127.0.0.1',          '2130706433' ],
	[ '192.168.0.1',        '192.168.0.1' ],
	[ '192.168.0.1',        '192.168.1' ],
	[ '0',                  '0.0.0' ],
	[ '0',                  '0.0' ],
);

our @ipv4_not_equal = (
	[ '127.0.0.1',         '127.0.0.2' ],
	[ '0.0',               '0.0.0.1' ],
	[ '0177.0.0.0',        '177.0.0.1' ],
	[ '0x11.0.0.0',        '11.0.0.1' ],
);

our @ipv6_equal = (
	[ '0:0:0:0:0:0:0:1',   '::1' ],
	[ '0::000:1',          '::1' ],
	[ '::FFFF:127.0.0.1',  '0:0:0:0:0:ffff:7f00:0001' ],
	[ '::',                '0::0:0' ],
	[ '::',                '0000:0000:0000:0000:0000:0000:0000:0000' ],
);

our @ipv6_not_equal = (
	[ '1:0:0:0:0:0:0:0',    '1:0:0:0:0:0:0:1' ],
	[ '::',                 '::1' ],
);

our @ipv6ipv4_equal = (
	[ '::ffff:7f00:0001',   '127.0.0.1' ],
	[ '0:0:0:0:0:ffff:0:0', '0.0.0.0' ],
	[ '0',                  '0:0:0:0:0:ffff:0:0' ],
	[ '127.0.0.1',          '::ffff:127.0.0.1' ],
	[ '0',                  '0:0:0:0:0:ffff::' ],
	[ '::ffff:127.0.0.1',   '127.0.0.1' ],
	[ '0:0:0:0:0:ffff::',   '0.0.0.0' ],
	[ '127.0.0.1',          '::ffff:7f00:1' ],
);

our @ipv6ipv4_not_equal = (
	[ '127.0.0.1',          '::ffff:127.0.0.2' ],
	[ '0',                  '0:0:0:0:0:ffff:0:1' ],
	[ '::ffff:127.0.0.1',   '127.0.0.2' ],
	[ '127.0.0.1',          '::ffff:7f00:2' ],
	[ '0',                  '0:0:0:0:0:ffff:0:2' ],
	[ '::ffff:7f01:0001',   '127.0.0.1' ],
	[ '0:0:0:0:0:ffff:0:1', '0.0' ],
);

our @wrong_ipv6ipv4 = (
	[ '0:0:0:0:0:fff1::' ],
	[ '::' ],
);

our @wrong_ip_net = (
	[ '192.168.0.1', '::/100',                     'Wrong combination IPv4 address and IPv6 network' ],
	[ '192.168.0.1', 'ff:: ff::',                  'Wrong combination IPv4 address and IPv6 network' ],
	[ '::',          '10.10.10.10/32',             'Wrong combination IPv6 address and IPv4 network' ],
	[ '::',          '10.10.10.10 255.255.255.0',  'Wrong combination IPv6 address and IPv4 network' ],

	[ '192.168.0.1', [ '1/32', '::/100',                      ], 'Wrong combination IPv4 address and IPv6 network' ],
	[ '192.168.0.1', [ '1/32', 'ff:: ff::',                   ], 'Wrong combination IPv4 address and IPv6 network' ],
	[ '::',          [ '::1/128', '10.10.10.10/32',           ], 'Wrong combination IPv6 address and IPv4 network' ],
	[ '::',          [ '::1/128', '10.10.10.10 255.255.255.0' ], 'Wrong combination IPv6 address and IPv4 network' ],
);

our @wrong_net = (
	[ '192.168.1.1', '192.168.0.1/33', 'IPv4 network and IPv6 mask' ],
	[ '192.168.1.1', '192.168.0.1 ::', 'IPv4 network and IPv6 mask' ],
	[ '::', ':: 255.255.255.255',      'IPv6 network and IPv4 mask' ],
	[ '::', '::/130',                  'IPv6 network and wrong mask' ],
	[ '::', ':: 1',                    'IPv6 network and IPv4 integer mask' ],
);

our @ipv4_in_range = (
	[ '0',                 '0/0' ],
	[ '255.255.255.255',   '0/0' ],
	[ '192.168.0.1',       '192.168.0.0/24' ],
	[ '10.10.10.11',       '10.10.10.8/30'  ],
	[ '10.10.10.8',        '10.10.10.8/30' ],
	[ '10.10.10.9',        '10.10.10.8/31' ],
	[ '10.255.255.255',    '10.0.0.0/8' ],
	[ '255.255.255.255',   '255.255.255.255/32' ],

	[ '10.10.10.10',       '10.10.10.8/29' ],
	[ '0xA0A0A0A',         '10.10.10.8/29' ],
	[ '01202405012',       '10.10.10.8/29' ],
	[ '012.012.012.012',   '10.10.10.8/29' ],
	[ '168430090',         '10.10.10.8/29' ],

	[ '10.10.10.10',       '0xA0A0A08/29' ],
	[ '0xA0A0A0A',         '0xA0A0A08/29' ],
	[ '01202405012',       '0xA0A0A08/29' ],
	[ '012.012.012.012',   '0xA0A0A08/29' ],
	[ '168430090',         '0xA0A0A08/29' ],

	[ '10.10.10.09',       '012.012.012.010/31' ],
	[ '0xA0A0A09',         '012.012.012.010/31' ],
	[ '01202405011',       '012.012.012.010/31' ],
	[ '012.012.012.011',   '012.012.012.010/31' ],
	[ '168430089',         '012.012.012.010/31' ],

	[ '10.10.10.09',       '168430088/31' ],
	[ '0xA0A0A09',         '168430088/31' ],
	[ '01202405011',       '168430088/31' ],
	[ '012.012.012.011',   '168430088/31' ],
	[ '168430089',         '168430088/31' ],

	[ '10.10.10.09',       '01202405010/30' ],
	[ '0xA0A0A09',         '01202405010/30' ],
	[ '01202405011',       '01202405010/30' ],
	[ '012.012.012.012',   '01202405010/30' ],
	[ '168430089',         '01202405010/30' ],

	[ '127.0.0.1',         '127.0.0.1' ],
	[ '0x7f.0.0.0x01',     '127.0.0.1' ],
	[ '2130706433',        '127.0.0.1' ],
	[ '017700000001',      '127.0.0.1' ],
	[ '0177.0.0.01',       '127.0.0.1' ],

	[ '172.16.5.2',        '172.0.0.0  255.0.0.0'     ],
	[ '0xAC100502',        '172.0.0.0  255.0.0.0'     ],
	[ '0xAC.0x10.0x5.0x2', '172.16.0.0 255.255.0.0'   ],
	[ '2886731010',        '172.16.0.0 255.255.0.0'   ],
	[ '025404002402',      '172.16.5.0 255.255.255.0' ],
	[ '0254.020.5.02',     '172.16.5.0 255.255.255.0' ],

	[ '172.16.5.2',        '0xAC.16.0x5.0 255.255.255.0'   ],
	[ '0xAC100502',        '0xAC.16.0x5.0 255.255.255.0'   ],
	[ '0xAC.0x10.0x5.0x2', '0xAC.16.0x5.0 255.255.255.0'   ],
	[ '2886731010',        '0xAC.0x10.0x5.0 255.255.255.0' ],
	[ '025404002402',      '0xAC.0x10.0x5.0 255.255.255.0' ],
	[ '0254.020.5.02',     '0xAC.0x10.0x5.0 255.255.255.0' ],

	[ '172.16.5.2',        '2886731008 255.255.255.128' ],
	[ '0xAC100502',        '2886731008 255.255.255.128' ],
	[ '0xAC.16.0x5.0x2',   '2886731008 255.255.255.128' ],
	[ '2886731010',        '2886731008 255.255.255.128' ],
	[ '025404002402',      '2886731008 255.255.255.128' ],
	[ '0254.020.5.02',     '2886731008 255.255.255.128' ],

	[ '172.16.5.2',        '025404002400 255.255.255.192' ],
	[ '0xAC100502',        '025404002400 255.255.255.192' ],
	[ '0xAC.0x10.0x5.0x2', '025404002400 255.255.255.192' ],
	[ '2886731010',        '025404002400 255.255.255.192' ],
	[ '025404002402',      '025404002400 255.255.255.192' ],
	[ '0254.020.5.02',     '025404002400 255.255.255.192' ],

	[ '172.16.5.2',        '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],
	[ '0xAC100502',        '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],
	[ '0xAC.16.0x5.0x2',   '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],
	[ '2886731010',        '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],
	[ '025404002402',      '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],
	[ '0254.020.5.02',     '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],

	[ '172.16.5.2',        '0254.020.5.0  0xFFfffff0' ],
	[ '0xAC100502',        '025404002400  0xFFfffff0' ],
	[ '0xAC.0x10.0x5.0x2', '2886731008    0xFFfffff0' ],
	[ '2886731010',        '0254.020.5.0  0xFFfffff0' ],
	[ '025404002402',      '0xAC.16.0x5.0 0xFFfffff0' ],
	[ '0254.020.5.02',     '172.16.5.0    0xFFfffff0' ],

	[ '172.16.5.2',        '0254.020.5.0    4294967288' ],
	[ '0xAC100502',        '025404002400    4294967288' ],
	[ '0xAC.16.0x5.0x2',   '2886731008      4294967288' ],
	[ '2886731010',        '0254.020.5.0    4294967288' ],
	[ '025404002402',      '0xAC.0x10.0x5.0 4294967288' ],
	[ '0254.020.5.02',     '172.16.5.0      4294967288' ],

	[ '172.16.5.1',        '0254.020.5.0   0377.0377.0377.0376' ],
	[ '0xAC100501',        '025404002400   0377.0377.0377.0376' ],
	[ '0xAC.0x10.0x5.0x1', '2886731008     0377.0377.0377.0376' ],
	[ '2886731009',        '0254.020.5.0   0377.0377.0377.0376' ],
	[ '025404002401',      '0xAC.020.0x5.0 0377.0377.0377.0376' ],
	[ '0254.020.5.01',     '172.16.5.0     0377.0377.0377.0376' ],
);

our @ipv4_not_in_range = (
	[ '1',                 '0/32' ],
	[ '192.168.0.1',       '192.168.1.0/24' ],
	[ '10.10.10.8',        '10.10.0.8/29'   ],
	[ '10.10.10.7',        '10.10.10.8/29'  ],
	[ '10.10.10.16',       '10.10.10.8/29'  ],
	[ '10.255.255.255',    '10.0.0.0/9'     ],

	[ '10.10.10.19',       '10.10.10.8/29' ],
	[ '0xA0A0A001',        '10.10.10.8/29' ],
	[ '01202405004',       '10.10.10.8/29' ],
	[ '012.012.012.07',    '10.10.10.8/29' ],
	[ '168430085',         '10.10.10.8/29' ],

	[ '10.10.10.4',        '0xA0A0A08/29' ],
	[ '0xA0A0A010',        '0xA0A0A08/29' ],
	[ '01202405007',       '0xA0A0A08/29' ],
	[ '012.012.012.020',   '0xA0A0A08/29' ],
	[ '168430097',         '0xA0A0A08/29' ],

	[ '10.10.10.07',       '012.012.012.010/31' ],
	[ '0xA0A0A07',         '012.012.012.010/31' ],
	[ '01202405007',       '012.012.012.010/31' ],
	[ '012.012.012.029',   '012.012.012.010/31' ],
	[ '168430097',         '012.012.012.010/31' ],

	[ '10.10.10.07',       '168430088/31' ],
	[ '0xA0A0A07',         '168430088/31' ],
	[ '01202405007',       '168430088/31' ],
	[ '012.012.012.029',   '168430088/31' ],
	[ '168430097',         '168430088/31' ],

	[ '10.10.10.07',       '01202405010/30' ],
	[ '0xA0A0A07',         '01202405010/30' ],
	[ '01202405007',       '01202405010/30' ],
	[ '012.012.012.029',   '01202405010/30' ],
	[ '168430097',         '01202405010/30' ],

	[ '127.0.0.2',         '127.0.0.1' ],
	[ '0x7f.0.0.0x02',     '127.0.0.1' ],
	[ '2130706434',        '127.0.0.1' ],
	[ '017700000002',      '127.0.0.1' ],
	[ '0177.0.0.02',       '127.0.0.1' ],

	[ '173.16.5.2',        '172.0.0.0  255.0.0.0'     ],
	[ '0xAD100502',        '172.0.0.0  255.0.0.0'     ],
	[ '0xAC.0x11.0x5.0x2', '172.16.0.0 255.255.0.0'   ],
	[ '2886796546',        '172.16.0.0 255.255.0.0'   ],
	[ '025404003002',      '172.16.5.0 255.255.255.0' ],
	[ '0254.020.6.02',     '172.16.5.0 255.255.255.0' ],

	[ '172.16.6.2',        '0xAC.16.0x5.0 255.255.255.0'   ],
	[ '0xAC100602',        '0xAC.16.0x5.0 255.255.255.0'   ],
	[ '0xAC.0x10.0x6.0x2', '0xAC.16.0x5.0 255.255.255.0'   ],
	[ '2886731266',        '0xAC.0x10.0x5.0 255.255.255.0' ],
	[ '025404003002',      '0xAC.0x10.0x5.0 255.255.255.0' ],
	[ '0254.020.6.02',     '0xAC.0x10.0x5.0 255.255.255.0' ],

	[ '172.16.5.129',      '2886731008 255.255.255.128' ],
	[ '0xAC100581',        '2886731008 255.255.255.128' ],
	[ '0xAC.16.0x5.0x81',  '2886731008 255.255.255.128' ],
	[ '2886731137',        '2886731008 255.255.255.128' ],
	[ '025404002601',      '2886731008 255.255.255.128' ],
	[ '0254.020.5.0201',   '2886731008 255.255.255.128' ],

	[ '172.16.5.193',      '025404002400 255.255.255.192' ],
	[ '0xAC1005C1',        '025404002400 255.255.255.192' ],
	[ '0xAC.0x10.5.0xC1',  '025404002400 255.255.255.192' ],
	[ '2886731201',        '025404002400 255.255.255.192' ],
	[ '025404002701',      '025404002400 255.255.255.192' ],
	[ '0254.020.5.0301',   '025404002400 255.255.255.192' ],

	[ '172.16.5.225',      '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],
	[ '0xAC1005E1',        '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],
	[ '0xAC.16.0x5.0xE1',  '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],
	[ '2886731233',        '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],
	[ '025404002741',      '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],
	[ '0254.020.5.0341',   '0254.020.5.0 0xFF.0xff.0xff.0xe0' ],

	[ '172.16.5.241',      '0254.020.5.0  0xFFfffff0' ],
	[ '0xAC1005F1',        '025404002400  0xFFfffff0' ],
	[ '0xAC.0x10.5.0xF1',  '2886731008    0xFFfffff0' ],
	[ '2886731249',        '0254.020.5.0  0xFFfffff0' ],
	[ '025404002761',      '0xAC.16.0x5.0 0xFFfffff0' ],
	[ '0254.020.5.0361',   '172.16.5.0    0xFFfffff0' ],

	[ '172.16.5.249',      '0254.020.5.0    4294967288' ],
	[ '0xAC1005F9',        '025404002400    4294967288' ],
	[ '0xAC.16.0x5.0xf9',  '2886731008      4294967288' ],
	[ '2886731257',        '0254.020.5.0    4294967288' ],
	[ '025404002771',      '0xAC.0x10.0x5.0 4294967288' ],
	[ '0254.020.5.0371',   '172.16.5.0      4294967288' ],

	[ '172.16.5.5',        '0254.020.5.0   0377.0377.0377.0376' ],
	[ '0xAC100505',        '025404002400   0377.0377.0377.0376' ],
	[ '0xAC.0x10.0x5.0x5', '2886731008     0377.0377.0377.0376' ],
	[ '2886731014',        '0254.020.5.0   0377.0377.0377.0376' ],
	[ '025404002406',      '0xAC.020.0x5.0 0377.0377.0377.0376' ],
	[ '0254.020.5.05',     '172.16.5.0     0377.0377.0377.0376' ],
);

our @ipv6_in_range = (
	[ '::',                                      '::/128' ],
	[ '::',                                      '::/0' ],
	[ '::1',                                     '::1' ],
	[ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', '::/0' ],
	[ '1:2:3:4:5:6:8000:8',                      '1:2:3:4:5:6:0::/96' ],
	[ '1:2:3:4:5:6:8000:F1',                     '1:2:3:4:5:6:8000::/112' ],
	[ '1:2:3:4:5:6:8000:3F',                     '1:2:3:4:5:6:8000:20/123' ],
	[ 'ff:ff:ff:ff:ff:ff:8000:0',                'ff:ff:ff:ff:ff:ff:8000::/127' ],
	[ 'ff:ff:ff:ff:ff:ff:8000:1',                'ff:ff:ff:ff:ff:ff:8000::/127' ],
	[ '::1',                                     '::1' ],
	[ '::1',                                     '::1/128' ],
	[ 'a0:a0:a0:a0:1::1',                        'a0:a0:a0:a0::/64' ],
	[ 'a0:b0:a0:a0:1::1',                        'a0::/16' ],
	[ 'a0ff:dd0:1234:a0:1::1',                   'a000::/8' ],
	[ '::ffff:10.10.10.10',                      '::ffff:0:0/96' ],
	[ '::ffff:127.0.0.255',                      '::ffff:127.0.0.0/120' ],
	[ '::ffff:10.10.10.9',                       '::ffff:10.10.10.8/127' ],
);

our @ipv6_not_in_range = (
	[ '::',                                      '::1/0' ],
	[ '::2',                                     '::1' ],
	[ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', '1::/0' ],
	[ '1:2:3:4:5:7:8000:8',                      '1:2:3:4:5:6:0::/96' ],
	[ '1:2:3:4:5:6:8001:F1',                     '1:2:3:4:5:6:8000::/112' ],
	[ '1:2:3:4:5:6:8000:40',                     '1:2:3:4:5:6:8000:20/123' ],
	[ 'ff:ff:ff:ff:ff:ff:8000:4',                'ff:ff:ff:ff:ff:ff:8000::/127' ],
	[ 'ff:ff:ff:ff:ff:ff:7FFF:0',                'ff:ff:ff:ff:ff:ff:8000::/127' ],
	[ '1::1',                                    '::1' ],
	[ '::11',                                    '::1/128' ],
	[ 'a0:a0:a0:a1:1::1',                        'a0:a0:a0:a0::/64' ],
	[ 'a1:b0:a0:a0:1::1',                        'a0::/16' ],
	[ 'b0ff:dd0:1234:a0:1::1',                   'a000::/8' ],
	[ '::fffe:0a0a:0a0a',                        '::ffff:0:0/96' ],
	[ '::ffff:127.0.1.255',                      '::ffff:127.0.0.0/120' ],
	[ '::ffff:10.10.10.12',                      '::ffff:10.10.10.8/127' ],
);

sub _invalid {
	my ($sub, $arr, $prefix, $args) = @_;

	my $arg_num = 0;
	if (defined $args) {
		my $i = -1;
		for my $arg (@$args) {
			$i++;
			next if $arg ne '$';
			$arg_num = $i;
			last;
		}
	} else {
		$args = [];
	}

	my $count = scalar @$arr;
	for my $addr (@$arr) {
		my @a = @$args;
		$a[$arg_num] = $addr->[0];
		ok !$sub->(@a), "$prefix: " . (defined $addr->[0] ? "'$addr->[0]'" : 'undef');
	}
	return $count;
}

sub invalid {
	my ($sub, $args) = @_;
	return _invalid($sub, \@invalid_addr,      'Invalid address',  $args) +
	       _invalid($sub, \@invalid_ipv4,      'Invalid IPv4',     $args) +
	       _invalid($sub, \@invalid_ipv6,      'Invalid IPv6',     $args) +
	       _invalid($sub, \@invalid_ipv6_ipv4, 'Invalid IPv6IPv4', $args);
}

sub _die_on {
	my ($sub, $arr, $prefix, $args) = @_;

	my $arg_num = 0;
	if (defined $args) {
		my $i = -1;
		for my $arg (@$args) {
			$i++;
			next if $arg ne '$';
			$arg_num = $i;
			last;
		}
	} else {
		$args = [];
	}

	my $count = scalar @$arr;
	for my $addr (@$arr) {
		my @a = @$args;
		$a[$arg_num] = $addr->[0];
		dies_ok {$sub->(@a) } "$prefix: " . (defined $addr->[0] ? "'$addr->[0]'" : 'undef');
	}
	return $count;
}

sub die_on_invalid {
	my ($sub, $args) = @_;
	return _die_on($sub, \@invalid_addr,      'Die on invalid address',  $args) +
	       _die_on($sub, \@invalid_ipv4,      'Die on invalid IPv4',     $args) +
	       _die_on($sub, \@invalid_ipv6,      'Die on invalid IPv6',     $args) +
	       _die_on($sub, \@invalid_ipv6_ipv4, 'Die on invalid IPv6IPv4', $args);
}


1;
