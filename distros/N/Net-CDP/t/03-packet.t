use Test::More tests => 99;

BEGIN {
	use_ok('Net::CDP::Packet', ':caps');
	use_ok('Net::CDP::IPPrefix');
}

my $packet = new Net::CDP::Packet();
isa_ok($packet, 'Net::CDP::Packet', 'CDP packet');
my $saved = $packet;

is($packet->version, 1, 'CDP packet: version field is valid');
is($packet->ttl, 180, 'CDP packet: TTL field is valid');
is($packet->capabilities, CDP_CAP_HOST, 'CDP packet: capabilities field is valid');

is($packet->ttl(200), 200, 'CDP packet: TTL field can be updated');

is($packet->device('foo'), 'foo', 'CDP packet: device field can be updated');
is($packet->device(undef), undef, 'CDP packet: device field can be removed');

my $address1 = new Net::CDP::Address('127.0.0.1');
my $address2 = new Net::CDP::Address('::1');
my @addresses = $packet->addresses([$address1, $address2]);
is(scalar @addresses, 2, 'CDP packet: addresses field has the correct number of entries');
isa_ok($addresses[0], 'Net::CDP::Address', 'IPv4 address');
isa_ok($addresses[1], 'Net::CDP::Address', 'IPv6 address');
is($addresses[0]->address, '127.0.0.1', 'CDP packet: addresses field has the IPv4 address');
is($addresses[1]->address, '::1', 'CDP packet: addresses field has the IPv6 address');

@addresses = $packet->addresses([]);
is(scalar @addresses, 0, 'CDP packet: addresses field can be cleared');

my $addresses = $packet->addresses(undef);
is($addresses, undef, 'CDP packet: addresses field can be removed');

is($packet->port('foo'), 'foo', 'CDP packet: port field can be updated');
is($packet->port(undef), undef, 'CDP packet: port field can be removed');

is($packet->capabilities(CDP_CAP_ROUTER), CDP_CAP_ROUTER, 'CDP packet: capabilities field can be updated');

is($packet->ios_version('foo'), 'foo', 'CDP packet: IOS version field can be updated');
is($packet->ios_version(undef), undef, 'CDP packet: IOS version field can be removed');

is($packet->platform('foo'), 'foo', 'CDP packet: platform field can be updated');
is($packet->platform(undef), undef, 'CDP packet: platform field can be removed');

my $ip_prefix1 = new Net::CDP::IPPrefix('127.0.0.1/8');
my $ip_prefix2 = new Net::CDP::IPPrefix('192.168.0.1/24');
my @ip_prefixes = $packet->ip_prefixes([$ip_prefix1, $ip_prefix2]);
is(scalar @ip_prefixes, 2, 'CDP packet: IP prefixes field has the correct number of entries');
isa_ok($ip_prefixes[0], 'Net::CDP::IPPrefix', 'IP prefix #1');
isa_ok($ip_prefixes[1], 'Net::CDP::IPPrefix', 'IP prefix #2');
is($ip_prefixes[0]->cidr, '127.0.0.0/8', 'CDP packet: IP prefixes field has the IP prefix #1');
is($ip_prefixes[1]->cidr, '192.168.0.0/24', 'CDP packet: IP prefixes field has the IP prefix #2');

@ip_prefixes = $packet->ip_prefixes([]);
is(scalar @ip_prefixes, 0, 'CDP packet: IP prefixes field can be cleared');

my $ip_prefixes = $packet->ip_prefixes(undef);
is($ip_prefixes, undef, 'CDP packet: IP prefixes field can be removed');

is($packet->vtp_management_domain('foo'), 'foo', 'CDP packet: VTP management domain field can be updated');
is($packet->vtp_management_domain(undef), undef, 'CDP packet: VTP management domain field can be removed');

is($packet->native_vlan(1234), 1234, 'CDP packet: native VLAN field can be updated');
is($packet->native_vlan(undef), undef, 'CDP packet: native VLAN field can be removed');

ok(!$packet->duplex(0), 'CDP packet: duplex field can be updated');
ok($packet->duplex(1), 'CDP packet: duplex field can be updated');
is($packet->duplex(undef), undef, 'CDP packet: duplex field can be removed');

my ($voice_vlan, $appliance_id) = $packet->voice_vlan(1234);
is($voice_vlan, 1234, 'CDP packet: voice VLAN field can be set');
is($appliance_id, 1, 'CDP packet: appliance ID field has sensible default');
($voice_vlan, $appliance_id) = $packet->voice_vlan(123, 2);
is($voice_vlan, 123, 'CDP packet: voice VLAN field can be updated');
is($appliance_id, 2, 'CDP packet: appliance ID field can be updated');
(undef, $appliance_id) = $packet->voice_vlan(12);
is($packet->voice_vlan(), 12, 'CDP packet: voice VLAN field can be retrieved in scalar context');
is($appliance_id, 2, 'CDP packet: appliance ID field does not change when voice VLAN field is updated');
($voice_vlan, $appliance_id) = $packet->voice_vlan(undef, 3);
is($voice_vlan, 12, 'CDP packet: voice VLAN field does not change when appliance ID field is updated');
is($appliance_id, 3, 'CDP packet: appliance ID field can be updated even when voice VLAN field is not');
($voice_vlan, $appliance_id) = $packet->voice_vlan(undef, undef);
is($voice_vlan, undef, 'CDP packet: voice VLAN field can be removed');
is($appliance_id, undef, 'CDP packet: appliance ID field can be removed');
$packet->voice_vlan(1);
($voice_vlan, $appliance_id) = $packet->voice_vlan(undef);
is($voice_vlan, undef, 'CDP packet: voice VLAN field can be removed by only passing one undef');
is($appliance_id, undef, 'CDP packet: appliance ID field can be removed by only passing one undef');

($voice_vlan, $appliance_id) = $packet->voice_vlan_query(1234);
is($voice_vlan, 1234, 'CDP packet: voice VLAN query field can be set');
is($appliance_id, 1, 'CDP packet: appliance ID query field has sensible default');
($voice_vlan, $appliance_id) = $packet->voice_vlan_query(123, 2);
is($voice_vlan, 123, 'CDP packet: voice VLAN query field can be updated');
is($appliance_id, 2, 'CDP packet: appliance ID query field can be updated');
(undef, $appliance_id) = $packet->voice_vlan_query(12);
is($packet->voice_vlan_query(), 12, 'CDP packet: voice VLAN query field can be retrieved in scalar context');
is($appliance_id, 2, 'CDP packet: appliance ID query field does not change when voice VLAN field is updated');
($voice_vlan, $appliance_id) = $packet->voice_vlan_query(undef, 3);
is($voice_vlan, 12, 'CDP packet: voice VLAN query field does not change when appliance ID field is updated');
is($appliance_id, 3, 'CDP packet: appliance ID query field can be updated even when voice VLAN field is not');
($voice_vlan, $appliance_id) = $packet->voice_vlan_query(undef, undef);
is($voice_vlan, undef, 'CDP packet: voice VLAN query field can be removed');
is($appliance_id, undef, 'CDP packet: appliance ID query field can be removed');
$packet->voice_vlan_query(1);
($voice_vlan, $appliance_id) = $packet->voice_vlan_query(undef);
is($voice_vlan, undef, 'CDP packet: voice VLAN query field can be removed by only passing one undef');
is($appliance_id, undef, 'CDP packet: appliance ID query field can be removed by only passing one undef');

is($packet->power_consumption(12345), 12345, 'CDP packet: power consumption field can be updated');
is($packet->power_consumption(undef), undef, 'CDP packet: power consumption field can be removed');

is($packet->mtu(1500), 1500, 'CDP packet: MTU field can be updated');
is($packet->mtu(undef), undef, 'CDP packet: MTU field can be removed');

ok(!$packet->trusted(0), 'CDP packet: extended trust field can be updated');
ok($packet->trusted(1), 'CDP packet: extended trust field can be updated');
is($packet->trusted(undef), undef, 'CDP packet: extended trust field can be removed');

is($packet->untrusted_cos(4), 4, 'CDP packet: untrusted COS field can be updated');
is($packet->untrusted_cos(undef), undef, 'CDP packet: untrusted COS field can be removed');

my $mgmt_address1 = new Net::CDP::Address('127.0.0.1');
my $mgmt_address2 = new Net::CDP::Address('::1');
my @mgmt_addresses = $packet->management_addresses([$mgmt_address1, $mgmt_address2]);
is(scalar @mgmt_addresses, 2, 'CDP packet: management addresses field has the correct number of entries');
isa_ok($mgmt_addresses[0], 'Net::CDP::Address', 'IPv4 address');
isa_ok($mgmt_addresses[1], 'Net::CDP::Address', 'IPv6 address');
is($mgmt_addresses[0]->address, '127.0.0.1', 'CDP packet: management addresses field has the IPv4 address');
is($mgmt_addresses[1]->address, '::1', 'CDP packet: management addresses field has the IPv6 address');

@mgmt_addresses = $packet->management_addresses([]);
is(scalar @mgmt_addresses, 0, 'CDP packet: management addresses field can be cleared');

my $mgmt_addresses = $packet->management_addresses(undef);
is($mgmt_addresses, undef, 'CDP packet: management addresses field can be removed');

$saved->addresses([new Net::CDP::Address('127.0.0.1'), new Net::CDP::Address('::1')]);
$saved->voice_vlan(1234, 5);
$saved->voice_vlan_query(1235, 6);
$saved->mtu(1500);
$saved->trusted(0);
$saved->untrusted_cos(7);
$saved->management_addresses([new Net::CDP::Address('127.0.0.1'), new Net::CDP::Address('::1')]);

my $cloned = clone $saved;
isa_ok($cloned, 'Net::CDP::Packet', 'Cloned packet');
bless $saved, '_Fake';
bless $cloned, '_Fake';
isnt(int($cloned), int($saved), 'Cloned packet: memory location is different from original');
bless $saved, 'Net::CDP::Packet';
bless $cloned, 'Net::CDP::Packet';

is($cloned->version, $saved->version, 'Cloned packet: version field is identical to original');
is($cloned->ttl, $saved->ttl, 'Cloned packet: TTL field is identical to original');
is($cloned->device, $saved->device, 'Cloned packet: device field is identical to original');

my $valid = 1;
my @cloned_addresses = $cloned->addresses;
my @saved_addresses = $saved->addresses;
while ($valid && @cloned_addresses && @saved_addresses) {
	my $cloned_address = shift @cloned_addresses;
	my $saved_address = shift @saved_addresses;
	next if !defined $cloned_address && !defined $saved_address;
	$valid &&= defined $cloned_address && ref $cloned_address eq 'Net::CDP::Address';
	$valid &&= defined $saved_address && ref $saved_address eq 'Net::CDP::Address';
	$valid &&= 
			defined $cloned_address->protocol &&
			defined $saved_address->protocol &&
			$cloned_address->protocol eq $saved_address->protocol;
	$valid &&= 
			defined $cloned_address->address &&
			defined $saved_address->address &&
			$cloned_address->address eq $saved_address->address;
	bless $saved_address, '_Fake';
	bless $cloned_address, '_Fake';
	$valid &&= int($cloned_address) != int($saved_address);
	bless $saved_address, 'Net::CDP::Address';
	bless $cloned_address, 'Net::CDP::Address';
}
ok($valid && !@cloned_addresses && !@saved_addresses, 'Cloned packet: address field is a deep copy of original');

is($cloned->port, $saved->port, 'Cloned packet: port field is identical to original');
is($cloned->capabilities, $saved->capabilities, 'Cloned packet: capabilities field is identical to original');
is($cloned->ios_version, $saved->ios_version, 'Cloned packet: IOS version field is identical to original');
is($cloned->platform, $saved->platform, 'Cloned packet: platform field is identical to original');

$valid = 1;
my @cloned_ip_prefixes = $cloned->ip_prefixes;
my @saved_ip_prefixes = $saved->ip_prefixes;
while ($valid && @cloned_ip_prefixes && @saved_ip_prefixes) {
	my $cloned_ip_prefix = shift @cloned_ip_prefixes;
	my $saved_ip_prefix = shift @saved_ip_prefixes;
	next if !defined $cloned_ip_prefix && !defined $saved_ip_prefix;
	$valid &&= defined $cloned_ip_prefix && ref $cloned_ip_prefix eq 'Net::CDP::IPPrefix';
	$valid &&= defined $saved_ip_prefix && ref $saved_ip_prefix eq 'Net::CDP::IPPrefix';
	$valid &&=
		defined $cloned_ip_prefix->network &&
		defined $saved_ip_prefix->network &&
		$cloned_ip_prefix->network eq $saved_ip_prefix->network;
	$valid &&= 
		defined $cloned_ip_prefix->length &&
		defined $saved_ip_prefix->length &&
		$cloned_ip_prefix->length == $saved_ip_prefix->length;
	bless $saved_ip_prefix, '_Fake';
	bless $cloned_ip_prefix, '_Fake';
	$valid &&= int($cloned_ip_prefix) != int($saved_ip_prefix);
	bless $saved_ip_prefix, 'Net::CDP::IPPrefix';
	bless $cloned_ip_prefix, 'Net::CDP::IPPrefix';
}
ok($valid && !@cloned_ip_prefixes && !@saved_ip_prefixes, 'Cloned packet: CDP IP prefix lists match');

is($cloned->vtp_management_domain, $saved->vtp_management_domain, 'Cloned packet: VTP management domain field is identical to original');
is($cloned->native_vlan, $saved->native_vlan, 'Cloned packet: native VLAN field is identical to original');
is($cloned->duplex, $saved->duplex, 'Cloned packet: duplex field is identical to original');

my ($cloned_voice_vlan, $cloned_appliance_id) = $cloned->voice_vlan();
my ($saved_voice_vlan, $saved_appliance_id) = $saved->voice_vlan();
is($cloned_voice_vlan, $saved_voice_vlan, 'Cloned packet: voice VLAN field is identical to original');
is($cloned_appliance_id, $saved_appliance_id, 'Cloned packet: appliance ID field is identical to original');

($cloned_voice_vlan, $cloned_appliance_id) = $cloned->voice_vlan();
($saved_voice_vlan, $saved_appliance_id) = $saved->voice_vlan();
is($cloned_voice_vlan, $saved_voice_vlan, 'Cloned packet: voice VLAN query field is identical to original');
is($cloned_appliance_id, $saved_appliance_id, 'Cloned packet: appliance ID query field is identical to original');

is($cloned->mtu, $saved->mtu, 'Cloned packet: MTU field is identical to original');
is($cloned->trusted, $saved->trusted, 'Cloned packet: extended trust field is identical to original');
is($cloned->untrusted_cos, $saved->untrusted_cos, 'Cloned packet: untrusted COS field is identical to original');

$valid = 1;
my @cloned_mgmt_addresses = $cloned->management_addresses;
my @saved_mgmt_addresses = $saved->management_addresses;
while ($valid && @cloned_mgmt_addresses && @saved_mgmt_addresses) {
	my $cloned_mgmt_address = shift @cloned_mgmt_addresses;
	my $saved_mgmt_address = shift @saved_mgmt_addresses;
	next if !defined $cloned_mgmt_address && !defined $saved_mgmt_address;
	$valid &&= defined $cloned_mgmt_address && ref $cloned_mgmt_address eq 'Net::CDP::Address';
	$valid &&= defined $saved_mgmt_address && ref $saved_mgmt_address eq 'Net::CDP::Address';
	$valid &&= 
			defined $cloned_mgmt_address->protocol &&
			defined $saved_mgmt_address->protocol &&
			$cloned_mgmt_address->protocol eq $saved_mgmt_address->protocol;
	$valid &&= 
			defined $cloned_mgmt_address->address &&
			defined $saved_mgmt_address->address &&
			$cloned_mgmt_address->address eq $saved_mgmt_address->address;
	bless $saved_mgmt_address, '_Fake';
	bless $cloned_mgmt_address, '_Fake';
	$valid &&= int($cloned_mgmt_address) != int($saved_mgmt_address);
	bless $saved_mgmt_address, 'Net::CDP::Address';
	bless $cloned_mgmt_address, 'Net::CDP::Address';
}
ok($valid && !@cloned_mgmt_addresses && !@saved_mgmt_addresses, 'Cloned packet: management address field is a deep copy of original');
