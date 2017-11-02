#!/usr/bin/perl
use strict;
use warnings;
use Net::AMQP::RabbitMQ;
use Getopt::Long;
use JSON;
use Time::HiRes qw(sleep);

our $VERSION = '0.1';

my $hostname = 'localhost';
my $user = 'guest';
my $password = 'guest';
my $channel = 1;
my $queue = 'test_out';

GetOptions(
    'host=s'          => \$hostname,
    'user=s'          => \$user,
    'password=s'      => \$password,
    'channel=i'       => \$channel,
    'queue=s'         => \$queue,
);

my $mq = Net::AMQP::RabbitMQ->new();
$mq->connect($hostname, { user => $user, password => $password });
$mq->channel_open($channel);
my $json = JSON->new;

my $i = 0;
my $uuids = {};
while (1) {
    my $msg = $mq->get($channel, $queue, {no_ack => 0});
    if (!$msg) {
        last;
    }
    printf "Got message: %s\n", $msg->{body};
    my $uuid = from_json($msg->{body})->{uuid};
    if ($uuids->{$uuid}) {
        croak("UUID $uuid already met!");
    } else {
        $uuids->{$uuid} = 1;
    }
}
printf "It seems that all %d messages are unique!\n", scalar(keys(%$uuids));

$mq->channel_close($channel);
$mq->disconnect();