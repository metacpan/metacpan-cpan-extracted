use Test::More tests => 23;

BEGIN { use_ok('Net::CDP'); use_ok('Net::CDP::Packet'); }

my @available = Net::CDP::ports();
ok(1, 'Net::CDP::ports');

SKIP: {
	skip 'Not running as root', 20
		if $> != 0;
	skip 'No network ports available', 20
		unless @available;

	my $valid = 1;
	foreach (@available) {
		$valid &&=
			eval { new Net::CDP($_); 1 } ||
			eval { new Net::CDP($_, promiscuous => 1); 1 };
	}
	ok($valid, 'All available ports could actually be opened');

	skip 'No loopback port available', 19
		unless grep /^lo/, @available;
	my $port = (grep /^lo/, @available)[0];
	
	my $cdp = new Net::CDP($port);
	isa_ok($cdp, 'Net::CDP');
	
	my $out = new Net::CDP::Packet($cdp);
	# Net::CDP::Packet is checked out in 03-packet.t
	is($out->port, $port, 'CDP port ID matches selected port');
	
	ok($cdp->send($out), 'Sending a CDP packet') or
		diag('The next test will probably freeze');
	
	my $in = $cdp->recv();
	isa_ok($in, 'Net::CDP::Packet');
	
	is($in->ttl, $out->ttl, 'CDP TTLs match');
	is($in->checksum, $out->checksum, 'CDP checksums match');
	
	$valid = 1;
	my @out_addresses = $out->addresses;
	my @in_addresses = $in->addresses;
	while ($valid && @out_addresses && @in_addresses) {
		my $out_address = shift @out_addresses;
		my $in_address = shift @in_addresses;
		next if !defined $out_address && !defined $in_address;
		$valid &&= defined $out_address && ref $out_address eq 'Net::CDP::Address';
		$valid &&= defined $in_address && ref $in_address eq 'Net::CDP::Address';
		$valid &&= 
			defined $out_address->protocol &&
			defined $in_address->protocol &&
			$out_address->protocol eq $in_address->protocol;
		$valid &&= 
			defined $out_address->address &&
			defined $in_address->address &&
			$out_address->address eq $in_address->address;
	}
	ok($valid && !@out_addresses && !@in_addresses, 'CDP address lists match');
	
	is($in->port, $out->port, 'CDP port IDs match');
	is($in->capabilities, $out->capabilities, 'CDP capabilities match');
	is($in->ios_version, $out->ios_version, 'CDP IOS versions match');
	is($in->platform, $out->platform, 'CDP IOS versions match');
	
	$valid = 1;
	my @out_ip_prefixes = $out->ip_prefixes;
	my @in_ip_prefixes = $in->ip_prefixes;
	while ($valid && @out_ip_prefixes && @in_ip_prefixes) {
		my $out_ip_prefix = shift @out_ip_prefixes;
		my $in_ip_prefix = shift @in_ip_prefixes;
		next if !defined $out_ip_prefix && !defined $in_ip_prefix;
		$valid &&= defined $out_ip_prefix && ref $out_ip_prefix eq 'Net::CDP::IPPrefix';
		$valid &&= defined $in_ip_prefix && ref $in_ip_prefix eq 'Net::CDP::IPPrefix';
		$valid &&=
			defined $out_ip_prefix->network &&
			defined $in_ip_prefix->network &&
			$out_ip_prefix->network eq $in_ip_prefix->network;
		$valid &&= 
			defined $out_ip_prefix->length &&
			defined $in_ip_prefix->length &&
			$out_ip_prefix->length == $in_ip_prefix->length;
	}
	ok($valid && !@out_ip_prefixes && !@in_ip_prefixes, 'CDP IP prefix lists match');
	
	is($in->vtp_management_domain, $out->vtp_management_domain, 'CDP VTP management domains match');
	is($in->native_vlan, $out->native_vlan, 'CDP native VLANs match');
	is($in->duplex, $out->duplex, 'CDP native VLANs match');

	$in = $cdp->recv(nonblock => 1);
	ok(!$in, 'Net::CDP::recv does not duplicate packets');

	$cdp = new Net::CDP(port => $port, enable_recv => 0);
	eval { $cdp->recv(nonblock => 1)	};
	isnt($@, '', 'Can not receive with enable_recv set to 0');

	$cdp = new Net::CDP(port => $port, enable_send => 0);
	eval { $cdp->send($out) };
	isnt($@, '', 'Can not send with enable_send set to 0');

	my $warned = '';
	$SIG{__WARN__} = sub { $warned = $_[0] };
	$cdp = new Net::CDP(port => $port, enable_recv => 0, enable_send => 0);
	isnt($warned, '', 'Setting enable_recv and enable_send both set to 0 produces warning');
}
