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
    my ($slack, $message) = @_;
    my $channel = $message->{channel};
    my $user = $message->{user};
    my $channel_name = $slack->find_channel_name($channel);
    my $user_name = $slack->find_user_name($user);
    $slack->send_message($channel => ":sushi:, $user_name");
});

$slack->start;
