#!/usr/bin/env perl 
use strict;
use warnings;

use Time::Moment;
use IO::Async::Loop;
use Net::Async::Slack;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'info';

my $loop = IO::Async::Loop->new;

my $token = shift or die 'Invalid token';
$loop->add(
    my $slack = Net::Async::Slack->new(
        client_id => '159837476818.159130832832',
        token     => $token,
    )
);

$log->info('Connecting to Slack RTM...');
my $rtm = $slack->rtm->get;
$log->info('Connection succeeded, watching for messages');

# Send out a message occasionally
my $timer;
if(my $channel = shift(@ARGV)) {
    $timer = $rtm->ryu
        ->timer(interval => 15)
        ->each(sub {
            $rtm->send_message(
                channel => 'D...',
                text    => 'good morning',
            )
        });
}

# Report whenever we get a message
$rtm->events
    ->filter_isa(qw(Net::Async::Slack::Event::Message))
    ->map(sub {
        sprintf "%s %s: %s", Time::Moment->from_epoch($_->ts)->to_string, $_->source_team_id, $_->text
    })
    ->say
    ->await;

# If the connection drops, then we're done

