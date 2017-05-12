
use warnings;
use strict;

use Test::More tests => 4;

use Socket;
use POSIX qw(strftime setlocale LC_ALL LC_CTYPE);
use POE;
use POE::Component::Server::Syslog::UDP;

our $TIME = time();

my $loc = eval { setlocale( LC_ALL, 'C' ) };

POE::Component::Server::Syslog::UDP->spawn(
		Alias		 => 'moocow',
		BindAddress  => '127.0.0.1',
		BindPort     => 4095,
		InputState   => \&client_input,
		ErrorState   => \&client_error,
);

POE::Session->create(
	inline_states      => {
		_start         => \&start,
		_stop          => sub {},
		sig            => \&sig,
		timeout        => \&timeout,
		send_test_data => \&send_test_data,
		_input         => \&client_input,
        _error 		   => \&client_error,
	},
);

POE::Kernel->run();
exit;

######################################

sub start {
	$_[HEAP]->{daddy}++;
	$_[KERNEL]->sig($_, 'sig') for qw(INT HUP TERM);

	$_[KERNEL]->call( 'moocow', 'register',
                { InputEvent => '_input', ErrorEvent => '_error' } );

	$_[KERNEL]->delay('send_test_data' => 0.5);

	$_[HEAP]->{timeout} = $_[KERNEL]->alarm_set('timeout' => time+9);
}

sub sig {
	$_[KERNEL]->call($_[HEAP]->{syslog}, 'shutdown');
	return;
}

sub timeout {
	fail("timed out");
	exit();
}


sub send_test_data {
	use IO::Socket::INET;

	my $sock = IO::Socket::INET->new(
		PeerPort  => 4095,
		PeerAddr  => '127.0.0.1',
		Proto     => 'udp',
		Broadcast => 1,
	) or die "Can't bind : $@\n";

	my $ts = strftime("%b %d %H:%M:%S", localtime($TIME));

	$sock->send("<1>$ts /USR/SBIN/CRON[16273]: (root) CMD (test -x /usr/lib/sysstat/sa1 && /usr/lib/sysstat/sa1)");
	$sock = undef;
}

sub client_input {

	$_[KERNEL]->alarm_remove($_[HEAP]->{timeout});

    my $msg = $_[ARG0];
	ok(defined $msg, "Got data stream");

	is_deeply(
		$msg,
		{
			msg       => '/USR/SBIN/CRON[16273]: (root) CMD (test -x /usr/lib/sysstat/sa1 && /usr/lib/sysstat/sa1)',
			pri       => 1,
			severity  => 1,
			host      => scalar gethostbyaddr(inet_aton('127.0.0.1'),AF_INET),
			facility  => 0,
			'time'    => $TIME,
			addr      => '127.0.0.1',
		},
		'input data is valid',
	);

	$_[KERNEL]->call('moocow', 'shutdown') if $_[HEAP]->{daddy};
	#POE::Kernel->stop();
}

sub client_error {
    fail("BAD MESSAGE: $_[ARG0]");
}


__END__
# sungo // vim: ts=4 sw=4 noexpandtab
