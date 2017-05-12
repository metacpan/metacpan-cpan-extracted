package SleepService;
use threads;
use threads::shared;
use Thread::Queue;
use strict;
use warnings;

# In this queue the master threads queue jobs for the slave worker
my $work_queue = new Thread::Queue;
# keeps track of how many free worker there are. can be below zero, if the
# number of worker reached max_workers, and more request are being recieved
# then being serviced.
my $free_workers : shared = 0;

sub new {
    my ($class, $params) = @_;
    print "Params: ", join(", ", map $_."=>".$params->{$_}, keys %$params), "\n";
    my $self = {
        threads_list => [],
        worker_created => 0,
        # limiting the number of created worker to some constant.
        max_workers => 5, 
    };
    return bless $self, $class;
}

sub AcceptRequest {
    my $self = shift;
    my $params = shift;
    # Primilinary checking. maybe we can satisfy this request immidiately,
    # and won't need to hand it off to a worker thread.
    if ($params->{trustLevel} < 3) {
        return (25, "Only trusted client can sleep here"); # kSTAFAccessDenied
    }
    if ($params->{request} == 0) {
        return (0, "still tired");
    }
    # Do we have a waiting worker? if not, create a new one.
    if ($free_workers <= 0 and $self->{worker_created} < $self->{max_workers}) {
        my $thr = threads->create(\&Worker);
        push @{ $self->{threads_list} }, $thr;
        $self->{worker_created}++;
    } else {
        lock $free_workers;
        $free_workers--;
    }
    my @array : shared = ($params->{requestNumber}, $params->{request});
    $work_queue->enqueue(\@array);
    return $STAF::DelayedAnswer;
}

sub DESTROY {
    my ($self) = @_;
    # The main service object itself is being copied with the worker threads,
    # and in the end of the program they are destroyed. this line make sure
    # that only the main thread will kill the worker thread.
    return unless threads->tid == 0;
    # Ask all the threads to stop, and join them.
    for my $thr (@{ $self->{threads_list} }) {
        $work_queue->enqueue('stop');
    }
    for my $thr (@{ $self->{threads_list} }) {
        eval { $thr->join() };
        print STDERR "On destroy: $@\n" if $@;
    }
}

sub Worker {
    my $loop_flag = 1;
    while ($loop_flag) {
        eval {
            # Step one - get the work from the queue
            my $array_ref = $work_queue->dequeue();
            if (not ref($array_ref) and $array_ref eq 'stop') {
                $loop_flag = 0;
                return;
            }
            my ($reqId, $reqTime) = @$array_ref;
            
            # Step two - sleep, and return an answer
            sleep($reqTime);
            STAF::DelayedAnswer($reqId, 0, "slept well");
            
            # Final Step - increase the number of free threads
            {
                lock $free_workers;
                $free_workers++;
            }
        }
    }
    return 1;
}

1;