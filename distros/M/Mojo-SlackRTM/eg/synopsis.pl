#!/usr/bin/env perl
use strict;
use warnings;
use lib "lib", "../lib";
use FindBin;
use Mojo::SlackRTM;
use Path::Tiny;

die "You must prepare TOKEN file first.\n" unless -f "$FindBin::Bin/TOKEN";
my ($token) = path("$FindBin::Bin/TOKEN")->lines({chomp => 1});

my $slack = Mojo::SlackRTM->new(token => $token);

$slack->on(message => sub {
    my ($slack, $event) = @_;
    my $channel_id = $event->{channel};
    my $user_id    = $event->{user};
    my $user_name  = $slack->find_user_name($user_id);
    my $text       = $event->{text};
    $slack->send_message($channel_id => "hello $user_name!");
});

$slack->on(reaction_added => sub {
    my ($slack, $event) = @_;
    my $reaction  = $event->{reaction};
    my $user_id   = $event->{user};
    my $user_name = $slack->find_user_name($user_id);
    $slack->log->info("$user_name reacted with $reaction");

    $slack->call_api("channels.list", {exclude_archived => 1}, sub {
        my ($slack, $tx) = @_;
        if ($tx->success and $tx->res->json("/ok")) {
            my $channels = $tx->res->json("/channels");
            $slack->log->info($_->{name}) for @$channels;
            return;
        }
        my $error = $tx->success ? $tx->res->json("/error") : $tx->error->{message};
        $slack->log->error($error);
    });
});


$slack->start;
