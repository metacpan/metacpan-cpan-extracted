#!/home/nicolaw/webroot/perl-5.8.7/bin/perl -w

use strict;
use Proc::DaemonLite qw(:all);

my $pid = init_server();
log_warn("Forked in to background PID $pid");

$SIG{__WARN__} = \&log_warn;
$SIG{__DIE__} = \&log_die;

for my $cid (1..4) {
	my $child = launch_child();
	if ($child == 0) {
		log_warn("I am child PID $$") while sleep 2;
		exit;
	} else {
		log_warn("Spawned child number $cid, PID $child");
	}
}

sleep 20;
kill_children();

