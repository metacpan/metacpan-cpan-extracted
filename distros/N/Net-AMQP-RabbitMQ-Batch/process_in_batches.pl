#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use JSON;
use Getopt::Long;
use Data::Dumper;
use lib './lib';
use Net::AMQP::RabbitMQ::Batch;
use Time::HiRes qw(sleep);

our $VERSION = '0.3000';
my $batch_size = 10;
my $ignore_size = 0;
GetOptions(
    'batch-size=i' => \$batch_size,
    'ignore-size'  => \$ignore_size,
);

# this is ony for signal handling in our infinite loop
my $should_stop = 0;
local $SIG{INT} = \&signal_handler;
local $SIG{TERM} = \&signal_handler;

# connect to RabbitMQ
my $rb = Net::AMQP::RabbitMQ::Batch->new('localhost', { user => 'guest', password => 'guest' }) or croak;

# do our processing in a infinite loop
while (!$should_stop) {
    # process a batch
    my $result = $rb->process({
        channel_id  => 1,
        from_queue  => 'test_in',
        routing_key => 'test_out',
        handler     => \&msg_handler, # this is processing handler
        batch       => {
            # number of messages in a batch
            size        => $batch_size,
            # time to wait if we don't have enough messages to form a complete batch
            timeout     => 2,
            # don't raise error if number of processed messages does not match number of incoming messages
            ignore_size => $ignore_size,
        },
        ignore_errors => 1
    });
    sleep 0.1;
}

exit(0);
###

# sample handler
# add "Processed: 1" to all messages
# emulates random processing failures
sub msg_handler {
    my $messages = shift;
    my $new_mesages = [];
    if (rand() < 0.05) {
        croak("Sometimes handler just dies");
    }
    if (rand() < 0.05) {
        carp('Returned empty hashref for no reason');
        return [];
    }

    for my $msg (@$messages) {
        my $body = from_json($msg->{body});
        $body->{processed} = 1;
        my $new_msg = {
            body         => to_json($body)
        };
        push(@$new_mesages, $new_msg);
    }
    if (rand() < 0.1 && @$new_mesages > 0) {
        carp('Dropped 1 message for no reason');
        pop(@$new_mesages);
    }
    printf "Processed %d messages\n", scalar(@$new_mesages);
    return $new_mesages;
}

# OS signal handler
sub signal_handler {
    $should_stop = 1;
    return;
}
