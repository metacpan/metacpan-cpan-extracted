use strict;
use warnings;

use Test::More tests => 28;

BEGIN {
  use_ok('NetAddr::MAC', qw( :normals ))
    or die "# NetAddr::MAC not available\n";
}

## more stuff needed here

# EUI-64 MAC normalization
is(mac_as_basic('10-00-5A-4D-BC-96-12-34'), lc('10005A4DBC961234'), 'EUI-64: mac_as_basic');
is(mac_as_ieee('1000.5A4D.BC961234'), lc('10:00:5A:4D:BC:96:12:34'), 'EUI-64: mac_as_ieee');
is(mac_as_cisco('10-00-5A-4D-BC-96-12-34'), lc('1000.5a4d.bc96.1234'), 'EUI-64: mac_as_cisco');
is(mac_as_pgsql('1000.5A4D.BC961234'), lc('10005A4D:BC961234'), 'EUI-64: mac_as_pgsql');
is(mac_as_singledash('1000.5A4D.BC961234'), lc('10005A4D-BC961234'), 'EUI-64: mac_as_singledash');

# Mixed case, delimiters, and odd formats
is(mac_as_basic('10:00:5a:4d:bc:96'), lc('10005a4dbc96'), 'Lowercase colons');
is(mac_as_basic('10-00-5A-4D-BC-96'), lc('10005A4DBC96'), 'Mixed case dashes');
is(mac_as_basic('1000.5A4D.BC96'), lc('10005A4DBC96'), 'Cisco style');
is(mac_as_basic('1,6,10:00:5A:4D:BC:96'), lc('10005A4DBC96'), 'BPR style');

# Invalid input
ok(!defined mac_as_basic(''), 'Empty string returns undef');
ok(!defined mac_as_basic('notamac'), 'Non-MAC string returns undef');
ok(!defined mac_as_basic('00:11:22:33:44'), 'Too short returns undef');
ok(!defined mac_as_basic('00:11:22:33:44:55:66:77:88'), 'Too long returns undef');

# IPv6-like input
ok(!defined mac_as_basic('2001:0db8::fe01'), 'IPv6-like string returns undef');
ok(!defined mac_as_basic('2001::0db8:fe05'), 'IPv6-like string returns undef');

# Edge case: single octet
ok(!defined mac_as_basic('ff'), 'Single octet returns undef');
is(mac_as_basic('10-00-5A-4D-BC-96'), lc('10005A4DBC96'),'Check mac_as_basic output');
is(mac_as_bpr('10-00-5A-4D-BC-96'), lc('1,6,10:00:5A:4D:BC:96'),'Check mac_as_bpr output');
is(mac_as_cisco('10-00-5A-4D-BC-96'), lc('1000.5A4D.BC96'),'Check mac_as_cisco output');
is(mac_as_ieee('1000.5A4D.BC96'), lc('10:00:5A:4D:BC:96'),'Check mac_as_ieee output');
# ipv6 needed
is(mac_as_microsoft('10005A4DBC96'), lc('10-00-5A-4D-BC-96'),'Check mac_as_cisco output');
is(mac_as_singledash('1000.5A4D.BC96'), lc('10005A-4DBC96'),'Check mac_as_singledash output');
is(mac_as_pgsql('1000.5A4D.BC96'), lc('10005A:4DBC96'),'Check mac_as_pgsql output');
is(mac_as_sun('1000.5A4D.BC96'), lc('10-0-5A-4D-BC-96'),'Check mac_as_sun output');
is(mac_as_tokenring('10-00-5A-4D-BC-96'), lc('08-00-5A-B2-3D-69'),'Check mac_as_tokenring output');
is(mac_as_tokenring('00-00-0C-F0-84-60'), lc('00-00-30-0F-21-06'),'Check mac_as_tokenring output');
is(mac_as_tokenring('AC-10-7B-3A-92-3C'), lc('35-08-DE-5C-49-3C'),'Check mac_as_tokenring output');
