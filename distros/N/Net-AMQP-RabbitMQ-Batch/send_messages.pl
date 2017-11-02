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
my $queue = 'test_in';
my $delivery_mode = 2;
my $messages = 200;
my $max_delay = 0.05;

GetOptions(
    'host=s'          => \$hostname,
    'user=s'          => \$user,
    'password=s'      => \$password,
    'channel=i'       => \$channel,
    'queue=s'         => \$queue,
    'delivery-mode=i' => \$delivery_mode,
    'messages=i'      => \$messages,
    'max-delay=f'     => \$max_delay,
);

my $mq = Net::AMQP::RabbitMQ->new();
$mq->connect($hostname, { user => $user, password => $password });
$mq->channel_open($channel);

my $i = 0;
while ($i < $messages) {
    my $uuid = time() * rand(10000) + $i;
    my $msg_body = to_json({msg => sprintf("Message number %d", $i), uuid => $uuid});
    $mq->publish($channel, $queue, $msg_body, undef, {delivery_mode => $delivery_mode});
    print "Sent message: $msg_body\n";
    sleep(rand() * $max_delay);
    $i++;
}
printf "Sent %d messages\n", $messages;

$mq->channel_close($channel);
$mq->disconnect();