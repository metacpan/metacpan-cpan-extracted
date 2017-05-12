use strict;
use warnings;

use Test::More;

use Protocol::SOCKS;
my $proto = new_ok('Protocol::SOCKS');
{
	is($proto->extract_address(\(my $v = "\x01\x01\x02\x03\x04")), '1.2.3.4', 'ipv4');
	is($v, '', 'removed all data');
}
{
	is($proto->extract_address(\(my $v = "\x04\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F\x10")), '102:304:506:708:90a:b0c:d0e:f10', 'ipv6');
	is($v, '', 'removed all data');
}
{
	is($proto->extract_address(\(my $v = "\x03\x11socks.example.com")), 'socks.example.com', 'hostname');
	is($v, '', 'removed all data');
}

for my $addr (
	'some.host.com',
	'localhost',
	'a-simple-longer-address-with-hyphens.example.com'
) {
	ok(length(my $buf = $proto->pack_fqdn($addr)), 'can pack address ' . $addr);
	is($proto->extract_address(\$buf), $addr, 'decodes correctly');
	is(length($buf), 0, 'empty afterwards');
}
for my $addr (
	'127.0.0.1',
	'4.2.2.1',
	'173.194.126.105'
) {
	ok(length(my $buf = $proto->pack_ipv4($addr)), 'can pack address ' . $addr);
	is($proto->extract_address(\$buf), $addr, 'decodes correctly');
	is(length($buf), 0, 'empty afterwards');
}
done_testing;


