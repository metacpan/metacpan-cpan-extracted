use Test::More tests => 40;

BEGIN { use_ok('Net::CDP::Manager'); }

my @available = cdp_ports;
ok(1, 'cdp_ports');

my $unknown_port = 'foo';
while (grep { $_ eq $unknown_port } @available) {
	$unknown_port .= 'foo';
}

cdp_args promiscuous => 1;
is({cdp_args}->{promiscuous}, 1, 'Promiscuous flag can be set');
cdp_args promiscuous => 0;
is({cdp_args}->{promiscuous}, 0, 'Promiscuous flag can be cleared');

my @x;

@x = cdp_manage_soft $unknown_port, $unknown_port;
ok(@x == 1 && $x[0] eq $unknown_port, 'Unknown soft port can be managed');

@x = cdp_managed;
ok(@x == 1 && $x[0] eq $unknown_port, 'Soft port is managed');
@x = cdp_hard;
is(@x, 0, 'Soft port is not in list of hard ports');
@x = cdp_soft;
ok(@x == 1 && $x[0] eq $unknown_port, 'Soft port is in list of soft ports');
@x = cdp_active;
is(@x, 0, 'Soft port is not active');
@x = cdp_inactive;
ok(@x == 1 && $x[0] eq $unknown_port, 'Soft port is inactive');

@x = cdp_manage_soft $unknown_port;
is(@x, 0, 'Unknown soft port is not returned when re-managed');

eval { cdp_manage $unknown_port };
isnt($@, '', 'Unknown soft port can not be hardened');

@x = cdp_managed;
ok(@x == 1 && $x[0] eq $unknown_port,
	'Unknown soft port appears only once in list of managed ports');

@x = cdp_unmanage $unknown_port;
ok(@x == 1 && $x[0] eq $unknown_port, 'Managed soft port can be unmanaged');

@x = cdp_managed;
is(@x, 0, 'Unknown soft port was actually removed');

@x = cdp_unmanage $unknown_port;
is(@x, 0, 'Unknown soft port can only be removed once');

eval { cdp_manage $unknown_port };
isnt($@, '', 'Unknown port can not be hard');

@x = cdp_managed;
is(@x, 0, 'Unknown hard port did not get added');

cdp_template->device('FooBarBaz');
is(cdp_template->device, 'FooBarBaz', 'Template can be modified');

eval { cdp_template(42) };
isnt($@, '', 'Template can not be screwed up');

SKIP: {
	skip 'Not running as root', 20
		if $> != 0;
	skip 'No loopback port available', 20
		unless grep /^lo/, @available;
	my $port = (grep /^lo/, @available)[0];
	
	@x = cdp_manage_soft $port;
	ok(@x == 1 && $x[0] eq $port, 'Known soft port can be managed');

	@x = cdp_manage $port;
	is($@, '', 'Known soft port can be hardened');
	is(@x, 0, 'Hardened port was not returned when re-managed');

	@x = cdp_managed;
	ok(@x == 1 && $x[0] eq $port, 'Hard port is managed');
	@x = cdp_hard;
	ok(@x == 1 && $x[0] eq $port, 'Hard port is in list of hard ports');
	@x = cdp_soft;
	is(@x, 0, 'Hard port is not in list of soft ports');
	@x = cdp_active;
	ok(@x == 1 && $x[0] eq $port, 'Hard port is active');
	@x = cdp_inactive;
	is(@x, 0, 'Hard port is not inactive');

	@x = cdp_manage_soft $port;
	is($@, '', 'Hard port can be softened');
	is(@x, 0, 'Softened port was not returned when re-managed');

	@x = cdp_managed;
	ok(@x == 1 && $x[0] eq $port, 'Known soft port is managed');
	@x = cdp_hard;
	is(@x, 0, 'Soft port is not in list of hard ports');
	@x = cdp_soft;
	ok(@x == 1 && $x[0] eq $port, 'Soft port is in list of soft ports');
	@x = cdp_active;
	ok(@x == 1 && $x[0] eq $port, 'Soft port is still active');
	@x = cdp_inactive;
	is(@x, 0, 'Soft port is still not inactive');
	
	my @success = cdp_send;
	ok(@success == 1 && $success[0] eq $port,
		'Sending a CDP packet was successful') or
		diag('The next test will probably freeze');
	
	my $in = cdp_recv;
	ok($in, 'Received the packet');
	isa_ok($in, 'Net::CDP::Packet', 'Received packet was valid');
	is($in->device, 'FooBarBaz', 'Received packet matches template');

	$in = cdp_recv 1;
	is($in, undef, 'Receive timeout works');
}
