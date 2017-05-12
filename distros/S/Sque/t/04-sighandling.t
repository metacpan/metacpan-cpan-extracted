use Test::More tests => 1;
use lib 't/lib';
use File::Temp 'tempfile';

use Sque;
use Sque::Job;
use Test::Worker;
use MockStomp;

my $sque = Sque->new(stomp => MockStomp->new);
my $worker = $sque->worker;
my $job = Sque::Job->new( sque => $sque, class => 'Test::Worker');
my $tempfile = tempfile;

# Mock out Test::Worker perform sub so we know when its finished
*Test::Worker::perform = sub {
    sleep 1;
    open(my $fh, '>', $tempfile) or die "Could not open file '$filename' $!";
    print $fh '1';
};

## Fork the worker so we can kill it while it sleeps
my $child_pid = fork;
if ($child_pid) {
    kill 3, $child_pid; # SIGQUIT
    sleep 2;
    open(my $fh, '<', $tempfile) or die "Could not open file '$filename' $!";
    is <$fh> => 1, 'Worker finished';
    done_testing;
} elsif ($child_pid == 0) {
    $worker->perform($job);
}

1;
