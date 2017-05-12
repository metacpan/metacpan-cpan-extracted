# -*- Mode: Perl; tab-width: 2; indent-tabs-mode: nil; -*-
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Net::Stomp;

my $amount_to_send = 32;
my $broker_host = '0.0.0.0';

note "About to insert $amount_to_send messages - be patient";
lives_ok {
    local $SIG{ALRM} = sub { die "failed to send $amount_to_send messages\n" }; # NB: \n required
    alarm(10);

    my $connection = Net::Stomp->new({
        hostname => $broker_host,
        port     => 61613,
    });
    $connection->connect;

    for my $n (1 .. $amount_to_send) {
        $connection->send({
            destination => '/queue/consume.many',
            body => "Message $n - " . scalar localtime
        })
    }
} q{inserted multiple jobs without dying};
note "Inserted $amount_to_send messages - cheers";

# now try to peel off messages
use Net::Stomp;
my $connection;
lives_ok {
    $connection = Net::Stomp->new({
        hostname => $broker_host,
        debug => 1,
        port     => 61613,
    });
    $connection->connect;
    $connection->subscribe({
        destination => '/queue/consume.many',
        ack         => 'client',
    });
} q{connected using Net::Stomp};

note "About to consume $amount_to_send frames - be patient";
lives_ok {
    local $SIG{ALRM} = sub { die "failed to consume $amount_to_send messages\n" }; # NB: \n required
    alarm(10);

    for (1 .. $amount_to_send) {
        my $frame = $connection->receive_frame;
        note "read frame $_: " . $frame->body;
        $connection->ack({frame => $frame});
    }
} qq{read $amount_to_send frames};
note "Consumed $amount_to_send frames - cheers";

done_testing;
