#!/usr/bin/env perl
use strict;
use warnings;

use Future::AsyncAwait;
use Syntax::Keyword::Try;
use IO::Async::Loop;
use Net::Async::Slack;
use JSON::MaybeUTF8 qw(:v2);
use Time::Moment;
use Path::Tiny;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'info';

binmode STDOUT, ':encoding(UTF-8)';
STDOUT->autoflush(1);
my $loop = IO::Async::Loop->new;

my ($token, $client_id) = splice @ARGV, 0, 2 or die 'Invalid token';
$loop->add(
    my $slack = Net::Async::Slack->new(
        client_id => $client_id,
        token     => $token,
    )
);

my @chan = @ARGV;
unless(@chan) {
    my $next;
    my $resp;
    do {
        $resp = await $slack->conversations_list(
            ($next ? (cursor => $next) : ()),
            limit => 200,
        );
        $log->tracef('Conversations: %s', format_json_text($resp));
        die 'not ok?' unless $resp->{ok};
        for my $chan ($resp->{channels}->@*) {
            next if $chan->{is_archived};
            $log->infof('%s - %s', $chan->{id}, $chan->{name});
            push @chan, $chan->{id};
        }
#        $log->infof('Conversations: %s', $resp);
        $next = $resp->{response_metadata}{next_cursor};
    } while $next;
}
$log->infof('Have %d channels to check', 0 + @chan);

my $count;
try {
    my $earliest_date = Time::Moment->now->minus_years(1);
    CHAN:
    for my $chan (@chan) {
        $log->infof('Checking channel %s', $chan);
        my $next;
        my $resp;
        do {
            await $loop->delay_future(after => 1);
            $resp = await $slack->conversations_history(
                channel => $chan,
                ($next ? (cursor => $next) : ()),
                limit => 200,
            );
            $log->tracef('Conversations: %s', format_json_text($resp));
            die 'not ok?' unless $resp->{ok};
            for my $event ($resp->{messages}->@*) {
                next unless $event->{ts};
                my $date = Time::Moment->from_epoch($event->{ts});
                ++$count->{$event->{user}}{$date->strftime('%Y-%m-%d')}{join ':', map { $_ // () } @{$event}{qw(type subtype)}};
                $log->infof('%s - %s - %s', $chan, $date->strftime('%Y-%m-%d %H:%M:%S'), $event->{text} // '');
                next CHAN if $date->is_before($earliest_date);
            }
            $next = $resp->{response_metadata}{next_cursor};
        } while $next;
    }
} catch($e) {
    $log->errorf('Failed... %s', $e);
}
path('slack-history.json')->spew_utf8(format_json_text($count));
