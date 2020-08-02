#!/usr/bin/perl

use 5.014;
use Sub::Daemon;


my $i = 0;

my $daemon = Sub::Daemon->new();

$daemon->_daemonize();

$daemon->spawn(
	nproc => 4,
	code  => sub {
		my $is_running = 1;
		$SIG{$_} = sub { $is_running = 0 } for qw( TERM INT );
		while($is_running) {
			sleep 1;
			warn "Loop... iter = $i";
			$i++;
			last if $i>=10;
		}
		
		$daemon->stop();
	},
);
