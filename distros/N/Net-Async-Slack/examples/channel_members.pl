#!/usr/bin/env perl
use strict;
use warnings;

=pod

Simple example showing how to list members in a Slack channel.

=cut

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
for my $chan (@chan) {
    try {
        my $resp = await $slack->conversations_members(
            channel => $chan,
        );
        $log->infof('Members for %s: %s', $chan, format_json_text($resp->{members}));
        die 'not ok?' unless $resp->{ok};
    } catch ($e) {
        $log->errorf('Failed to get channel members for %s - %s', $chan, $e);
    }
}
