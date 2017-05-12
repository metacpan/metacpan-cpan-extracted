#!perl -Tw

use Test::More tests => (1 + 5 + 7 + 2 * 16);

$fpid = undef;

BEGIN {
	use_ok( 'Net::PJLink', ':RESPONSES' ) || print "Bail out!\n";
}
END {
	kill $fpid if (defined $fpid && $fpid > 0);
}

%listen_opts = (
	Listen		=> 1,
	LocalAddr	=> 'localhost',
	LocalPort	=> 55555,
	Proto		=> 'tcp',
	Timeout		=> 5,
	Reuse		=> 1,
);
%connect_opts = (
	PeerAddr	=> 'localhost',
	PeerPort	=> 55555,
	Proto		=> 'tcp',
);

@cmd_resp_data = (
	[ "%1POWR 1\r" => "%1POWR=OK\r",
	  sub { $_[0]->set_power(1); } => OK, "set_power 1" ],

	[ "%1POWR 0\r" => "%1POWR=OK\r",
	  sub { $_[0]->set_power(0); } => OK, "set_power 0" ],

	[ "%1POWR ?\r" => "%1POWR=2\r",
	  sub { $_[0]->get_power(); } => POWER_COOLING, "get_power" ],

	[ "%1INPT 12\r" => "%1INPT=OK\r",
	  sub { $_[0]->set_input(INPUT_RGB, 2); } => OK, "set_input" ],

	[ "%1INPT ?\r" => "%1INPT=12\r",
	  sub { $_[0]->get_input(); } => [INPUT_RGB, 2], "get_input" ],

	[ "%1AVMT 21\r" => "%1AVMT=OK\r",
	  sub { $_[0]->set_audio_mute(1); } => OK, "set_audio_mute" ],

	[ "%1AVMT 10\r" => "%1AVMT=OK\r",
	  sub { $_[0]->set_video_mute(0); } => OK, "set_video_mute" ],

	[ "%1AVMT ?\r" => "%1AVMT=21\r",
	  sub { $_[0]->get_av_mute(); } => [1, 0], "get_av_mute" ],

	[ "%1ERST ?\r" => "%1ERST=012012\r",
	  sub { $_[0]->get_status(); } => {
			'fan'	=> OK,
			'lamp'	=> WARNING,
			'temp'	=> ERROR,
			'cover'	=> OK,
			'filter'=> WARNING,
			'other'	=> ERROR,
		}, "get_status" ],

	[ "%1LAMP ?\r" => "%1LAMP=123 1 456 0 789 1\r",
	  sub { $_[0]->get_lamp_info(); } => [
			[1, 123],
			[0, 456],
			[1, 789],
		], "get_lamp_info" ],

	[ "%1INST ?\r" => "%1INST=51 52 41 31 32 21 22 11\r",
	  sub { $_[0]->get_input_list(); } => [
			[INPUT_NETWORK, 1],
			[INPUT_NETWORK, 2],
			[INPUT_STORAGE, 1],
			[INPUT_DIGITAL, 1],
			[INPUT_DIGITAL, 2],
			[INPUT_VIDEO, 1],
			[INPUT_VIDEO, 2],
			[INPUT_RGB, 1],
		], "get_input_list" ],

	[ "%1NAME ?\r" => "%1NAME=prjname\r",
	  sub { $_[0]->get_name(); } => 'prjname', "get_name" ],

	[ "%1INF1 ?\r" => "%1INF1=mfgname\r",
	  sub { $_[0]->get_manufacturer(); } => 'mfgname', "get_manufacturer" ],

	[ "%1INF2 ?\r" => "%1INF2=prodname\r",
	  sub { $_[0]->get_product_name(); } => 'prodname', "get_product_name" ],

	[ "%1INFO ?\r" => "%1INFO=other other other other\r",
	  sub { $_[0]->get_product_info(); } => 'other other other other', "get_product_info" ],

	[ "%1CLSS ?\r" => "%1CLSS=1\r",
	  sub { $_[0]->get_class(); } => 1, "get_class" ],
);

my $auth = 7;
my $tests_per_cmd = 2;
my $cmds = $tests_per_cmd * (scalar @cmd_resp_data);
#plan tests => (3 + $auth + $cmds);

SKIP: {
	use_ok( 'IO::Socket::INET' )
		|| skip("Test requires IO::Socket::INET", 4 + $auth + $cmds);
	use_ok( 'IO::Select' )
		|| skip("Test requires IO::Select", 3 + $auth + $cmds);

	$srv = IO::Socket::INET->new(%listen_opts);
	ok( defined $srv, "Create listen socket" )
		|| skip("Cannot listen on localhost:55555", 2 + $auth + $cmds);
	$cli = IO::Socket::INET->new(%connect_opts);
	ok( defined $cli, "Connect to listener" )
		|| skip("Cannot connect to localhost:55555", 1 + $auth + $cmds);
	ok( $cli->send('test'), "Send data to listener" )
		|| skip("Cannot send data to localhost:55555", 0 + $auth + $cmds);
	$srv->close;
	undef $srv;
	undef $cli;

	$prj = Net::PJLink->new(
		host	=> $listen_opts{'LocalAddr'},
		port	=> $listen_opts{'LocalPort'},
	);

	isa_ok( $prj, Net::PJLink, "Create Net::PJLink instance" );
	is( $prj->{'port'}, $listen_opts{'LocalPort'},
	    "Check that port is set correctly" );

	ok( $prj->set_auth_password('JBMIAProjectorLink'),
	    "Set auth_password" );
	is( $prj->{'auth_password'}, 'JBMIAProjectorLink',
	    "Check for correct password" );

	spawn(\&netlisten_auth) || skip("Cannot fork listener process", 3 + $cmds);
	is( $prj->set_power(1), OK, "Send authenticated command" );
	waitpid($fpid, 0);
	ok( $?, "Listener status for auth command" );
	undef $fpid;
	ok( $prj->set_auth_password(), "Disable auth_password" );

	foreach my $d (@cmd_resp_data) {
		spawn(\&netlisten_cmd, $d->[0], $d->[1]) || skip("Cannot fork listener process", $cmds);
		is_deeply( $d->[2]->($prj), $d->[3], $d->[4] );
		waitpid($fpid, 0);
		ok( $?, "Listener status for " . $d->[4] );
		undef $fpid;
		$cmds -= $tests_per_cmd;
	}

} # end SKIP clock

sub netlisten_auth {
	my $c = shift;
	my($status, $msg);
	$c->send("PJLINK 1 498e4a67\r");
	$status = $c->recv($msg, 256);
	if ($msg =~ /^5d8409bc1c3fa39749434aa3a5c38682%1POWR \?\r$/) {
		$c->send("%1POWR=0\r");
	} else {
		diag "auth_password failed: $msg";
		return 0;
	}
	$status = $c->recv($msg, 256);
	if ($msg =~ /^%1POWR 1\r$/) {
		$c->send("%1POWR=OK\r");
	} else {
		diag "unexpected command: $msg";
		return 0;
	}
	return 1;
}

sub netlisten_cmd {
	my($c, $recv, $send) = @_;
	unless ($c) {
		diag "netlisten_cmd: socket is bad";
		return 0;
	}
	my $msg;
	$c->send("PJLINK 0\r");
	my $status = $c->recv($msg, 256);
	if ($msg ne $recv) {
		diag "netlisten_cmd: got $msg";
		return 0;
	}
	if (length $send == 0) {
		diag "netlisten_cmd: zero length \$send string";
	}
	$c->send($send);
	return 1;
}

sub spawn {
	my $coderef = shift;

	if (!defined($fpid = fork)) {
		return 0;
	} elsif ($fpid) { # parent
		sleep 0.2 until (kill 0, $fpid);
		sleep 1;
		return 1;
	}
	# child
	$srv = IO::Socket::INET->new(%listen_opts);
	exit 0 unless (defined $srv);
	my $c;
	my $done = 1;
	until (defined($c = $srv->accept())) {
		diag "wait accept...";
		exit 0 if ($done == 0);
		$done--;
	}
	$c->autoflush(1);
	exit &$coderef($c, @_);
}

