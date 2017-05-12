#!/usr/bin/perl
#
# Test case - Make sure that creating multiple Senders is OK
#

use strict;
use Test::Simple tests => 2;

use Data::Serializer;
use Data::Dumper;

my $qname = "testq";

disable Log::Channel "Spread::Queue";
disable Log::Channel "Spread::Session";

# launch sqm
my $sqm_pid;
if ($sqm_pid = fork) {
    # parent
} else {
    # launch queue manager

    my $PERLLIB = join(":", @INC);
    exec "PERLLIB=$PERLLIB blib/script/sqm $qname";
    exit;
}

# launch worker
my $worker_pid;
if ($worker_pid = fork) {
    # parent
} else {
    # launch worker
    use Spread::Queue::Worker;

    my $worker = new Spread::Queue::Worker(QUEUE => $qname,
					   SERIALIZER => new Data::Serializer(serializer => "YAML"),
					   CALLBACK => sub {
					       my ($worker, $originator, $input) = @_;
					       my $output = {
							     response => "I heard you!",
							    };
					       $worker->respond($originator, $output);
					       $worker->terminate;
					       return $output;
					   }
					  );

    $worker->run;

    exit;
}

sleep 3; # wait for the sqm and worker to start

# this is the sender

use Spread::Queue::Sender;

my $sender1 = new Spread::Queue::Sender(QUEUE => $qname,
				       SERIALIZER => new Data::Serializer(serializer => "YAML",
									  portable => 0,
									 ),
				      );
my $sender2 = new Spread::Queue::Sender(QUEUE => "fooq",
				       SERIALIZER => new Data::Serializer(serializer => "YAML",
									  portable => 0,
									 ),
				      );
$sender1->submit({
		 name1 => 'value1',
		 name2 => 'value2',
		});
my $response = $sender1->receive;
ok($response->{response} eq "I heard you!", 'end-to-end');

#sleep 3;

######################################################################

kill 15, $sqm_pid;

ok(1);

exit;
