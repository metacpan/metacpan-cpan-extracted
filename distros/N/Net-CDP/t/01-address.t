use Test::More tests => 17;

BEGIN { use_ok('Net::CDP::Address', ':protos'); }

my $address = new Net::CDP::Address('127.0.0.1');
isa_ok($address, 'Net::CDP::Address', 'IPv4 address');

is($address->protocol, CDP_ADDR_PROTO_IPV4, 'IPv4 address: protocol is valid');
is($address->address, '127.0.0.1', 'IPv4 address: address is valid');
is($address->packed, "\x7f\x00\x00\x01", 'IPv4 address: packed is valid');

$address = new Net::CDP::Address('0:0:0::1');
isa_ok($address, 'Net::CDP::Address', 'IPv6 address');

is($address->protocol, CDP_ADDR_PROTO_IPV6, 'IPv6 address: protocol is valid');
is($address->address, '::1', 'IPv6 address: address is valid');
is($address->packed, ("\x00" x 15) . "\x01", 'IPv6 address: packed is valid');

$address = new Net::CDP::Address(CDP_ADDR_PROTO_APPLETALK, "\x01\x02\x03\x04");
isa_ok($address, 'Net::CDP::Address', 'Non-IP address');

is($address->protocol, CDP_ADDR_PROTO_APPLETALK, 'Non-IP address: protocol is valid');
is($address->packed, "\x01\x02\x03\x04", 'Non-IP address: packed is valid');

my $cloned = clone $address;
isa_ok($cloned, 'Net::CDP::Address', 'Cloned address');
bless $address, '_Fake';
bless $cloned, '_Fake';
isnt(int($cloned), int($address), 'Cloned address: memory location is different from original');
bless $address, 'Net::CDP::Address';
bless $cloned, 'Net::CDP::Address';

is($cloned->protocol, $address->protocol, 'Cloned address: protocol is identical to original');
is($cloned->address, $address->address, 'Cloned address: address is identical to original');
is($cloned->packed, $address->packed, 'Cloned address: packed is identical to original');
