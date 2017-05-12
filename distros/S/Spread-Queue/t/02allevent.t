#!/usr/bin/perl

use strict;
use Test::Simple tests => 2;

BEGIN {
    $ENV{LOG_CHANNEL_CONFIG} = "t/logging.xml";
}

use Data::Dumper;

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
    # parent
} else {
    # launch worker

    use Event qw(loop unloop);
    use Spread::Queue::Worker;

    my $worker = new Spread::Queue::Worker(QUEUE => $qname,
					   CALLBACK => sub {
					       my ($worker, $originator, $input) = @_;
					       sleep 1;

					       my $output = {
							     response => "I heard you!",
							    };
					       $worker->respond($originator, $output);
					       $worker->terminate;
					       Event::unloop;
					       return $output;
					   }
					  );
    $worker->setup_Event;
    Event::loop;
    exit;
}

sleep 3; # wait for the sqm and worker to start

# this is the sender

use Event qw(loop unloop);
use Spread::Queue::Sender;
my $sender = new Spread::Queue::Sender(QUEUE => $qname);
$sender->submit({
		 name1 => 'value1',
		 name2 => 'value2',
		});
my $response = $sender->receive;
ok($response->{response} eq "I heard you!", 'end-to-end');

sleep 3;

######################################################################

kill 15, $sqm_pid;

ok(1);

exit;
