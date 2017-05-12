package POE::Component::MessageQueue::Test::ForkRun;
use strict;
use warnings;
use POSIX;
use Exporter qw(import);
our @EXPORT = qw(start_fork stop_fork);

sub start_fork {
	my $pid      = fork;
	return $pid if $pid;

	$_[0]->();
	use POE;
	$poe_kernel->run();
	exit 0;
}

sub stop_fork {
	my $pid = shift;

	my $killed = kill TERM => $pid;
	my $wait = waitpid($pid => 0);

	return ($killed == 1 && $wait == $pid);
}

1;
