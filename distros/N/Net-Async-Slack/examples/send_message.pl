#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::Slack;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'trace';

my $loop = IO::Async::Loop->new;

my $token = shift or die 'Invalid token';
$loop->add(
    my $slack = Net::Async::Slack->new(
        client_id => '159837476818.159130832832',
        token     => $token,
    )
);

my $channel = shift(@ARGV);
$slack->send_message(
    channel => $channel,
    text    => 'hello',
)->get;

$slack->send_message(
    channel => $channel,
    attachments => [
        {
            text => 'a task',
            color => '#205080',
            actions => [
                { name => 'action', text => 'Act on it', type => 'button', value => 'act' },
                { name => 'action', text => 'Move it to the backlog', type => 'button', value => 'backlog' },
                { name => 'action', text => 'Veto', type => 'button', value => 'veto', confirm => {
                    "title"        => "Veto this task",
                    "text"         => "This will have a chilling effect on anyone actually implementing the task. Sure you want to continue?",
                    "ok_text"      => "Yes",
                    "dismiss_text" => "No"
                } },
            ],
        }
    ],
)->get;
