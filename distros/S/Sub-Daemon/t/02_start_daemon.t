#!/usr/bin/perl

use Test::More tests => 3;

use Sub::Daemon;


my $i = 0;

my $daemon = Sub::Daemon->new();

ok(ref $daemon eq 'Sub::Daemon');

$daemon->_daemonize(debug => 1);

my $t = AE::timer(3, 0, sub {
		my $pidfile = $daemon->pidfile();
		open my $fi, $pidfile;
		my $pid = <$fi>;
		chomp $pid;
		close $fi;

		print "Killing daemon PID=$pid\n";

		ok(kill '-0', $pid);
		ok(kill 'INT', $pid);		
	},
);

$daemon->spawn(
	nproc => 1,
	code  => sub {
		my $is_running = 1;
		$SIG{$_} = sub { $is_running = 0 } for qw( TERM INT );
		while($is_running) {
			sleep 1;
			warn "Loop... iter = $i";
			$i++;
		}
	},
);





1;


