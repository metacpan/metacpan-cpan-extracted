#!perl -Tw

use Test::More tests => (1 + 4 + 16 + 11 + 2 + 6 + 2 + 2);

BEGIN {
	use_ok( 'Net::PJLink' ) || print "Bail out!\n";
}

my @cmd_methods = (
	\&Net::PJLink::set_power, \&Net::PJLink::set_power, \&Net::PJLink::get_power,
	\&Net::PJLink::set_input, \&Net::PJLink::get_input, \&Net::PJLink::set_audio_mute,
	\&Net::PJLink::set_video_mute, \&Net::PJLink::get_av_mute, \&Net::PJLink::get_status,
	\&Net::PJLink::get_lamp_info, \&Net::PJLink::get_input_list, \&Net::PJLink::get_name,
	\&Net::PJLink::get_manufacturer, \&Net::PJLink::get_product_name,
	\&Net::PJLink::get_product_info, \&Net::PJLink::get_class
);
my %COMMAND = (
	power		=> 'POWR',
	input		=> 'INPT',
	mute		=> 'AVMT',
	status		=> 'ERST',
	lamp		=> 'LAMP',
	input_list	=> 'INST',
	name		=> 'NAME',
	mfr		=> 'INF1',
	prod_name	=> 'INF2',
	prod_info	=> 'INFO',
	class		=> 'CLSS',
);

#plan tests => (4 + @cmd_methods + keys(%COMMAND) + 6);

# test methods
my $prj = Net::PJLink->new(host => '127.255.255.1');
isa_ok( $prj, Net::PJLink, 'Create instance' );
can_ok( $prj, qw( set_auth_password close_connection close_all_connections
	add_hosts remove_hosts ) );
can_ok( $prj, qw( set_power get_power set_input get_input set_audio_mute
	set_video_mute get_av_mute get_status get_lamp_info get_input_list
	get_name get_manufacturer get_product_name get_product_info
	get_class ) );
is( $prj->{'port'}, Net::PJLink::PJLINK_PORT, "Check for default port" );
foreach my $method (@cmd_methods) {
	is( &$method($prj, 1, 1), Net::PJLink::ERR_NETWORK,
	    "Check for correct response" );
}

# test command building
while (my($cmd_name, $cmd_sym) = each %COMMAND) {
	is( $prj->_build_command($cmd_name, 'TEST #,012 VAL'),
	    "%1$cmd_sym TEST #,012 VAL\r",
	    "Build $cmd_name command");
}

# test try_once behaviour
$prj = Net::PJLink->new(
	host		=> '127.255.255.1',
	try_once	=> 1,
);
isa_ok( $prj, Net::PJLink, 'Create instance' );
$prj->get_power();
is( $prj->get_power(), undef, "Check try_once parameter" );

# test authentication sanity
ok( not(defined $prj->{'auth_password'}),
    "Check that auth_password is not set by default" );
$prj = Net::PJLink->new(
	host		=> '127.255.255.1',
	try_once	=> 1,
	auth_password	=> 'asdfghjkl',
);
is( $prj->{'auth_password'}, 'asdfghjkl',
    "Check that constructor sets auth_password correctly" );
is( $prj->set_auth_password('abcdefg'), 1,
    "Check that set_auth_password works" );
is( $prj->{'auth_password'}, 'abcdefg',
    "Check that auth_password was set correctly" );
{ # catch warning message
	local *STDERR;
	my $stderr;
	open STDERR, '>', \$stderr;
	is( $prj->set_auth_password('111111111111111111111111111111111'), 0,
	    "Check that bad password is rejected" );
}

ok( not($prj->{'batch'}), "Check default batch_mode state" );

# test add_hosts
$prj->add_hosts('127.0.0.1', ['127.0.0.2', '127.0.0.3']);
is( scalar keys %{$prj->{'host'}}, 4, "Check that add_hosts works" );

ok( $prj->{'batch'}, "Check that batch_mode is enabled" );

# test remove_hosts
$prj->remove_hosts('127.255.255.1', ['127.0.0.1', '127.0.0.2']);
is( scalar keys %{$prj->{'host'}}, 1, "Check that remove_hosts works" );

ok( $prj->{'batch'}, "Check that batch_mode is not changed" );
