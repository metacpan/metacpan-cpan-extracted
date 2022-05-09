#!/usr/bin/env perl
use strict;
use warnings;

no indirect qw(fatal);
use List::UtilsBy qw(extract_by);
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

my @user = extract_by { /^U/ } @ARGV;
my @chan = extract_by { /^C/ } @ARGV;
die "have more things in ARGV and not sure what they are: @ARGV" if @ARGV;

for my $chan (@chan) {
    $log->infof('Adding %s to channel %s', \@user, $chan);
    my $resp = await $slack->conversations_invite(
        users => \@user,
        channel => $chan,
    );
    $log->infof('Invitation: %s', format_json_text($resp));
}
