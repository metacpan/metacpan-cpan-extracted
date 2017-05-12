#!/usr/bin/perl

use strict;
use Test::Simple tests => 2;

use Data::Dumper;

disable Log::Channel "Spread::Queue";
disable Log::Channel "Spread::Session";

my $qname = "testq";

# launch sqm
my $sqm_pid;
if ($sqm_pid = fork) {
    # parent
} else {
    # launch queue manager

    my $PERLLIB = join(":", @INC);
    exec "PERLLIB=$PERLLIB ./sqm $qname";
    exit;
}

# launch worker
my $worker_pid;
if ($worker_pid = fork) {
    # worker

    use Event qw(loop unloop);
    use Spread::Queue::Worker;

    my $worker = new Spread::Queue::Worker(QUEUE => $qname,
					   CALLBACK => sub {
					       my ($worker, $originator, $input) = @_;
					       ok(1);
					       $worker->terminate;
					       Event::unloop;
					   }
					  );
    $worker->setup_Event;
    Event::loop;
    sleep 1;
} else {
    # sender

    sleep 3; # wait for the sqm and worker to start

    use Event qw(loop unloop);
    use Spread::Queue::Sender;
    my $sender = new Spread::Queue::Sender(QUEUE => $qname);
    $sender->submit({
		     name1 => 'value1',
		     name2 => 'value2',
		    });
    exit;
}

######################################################################

kill 15, $sqm_pid;

ok(1);

exit;
