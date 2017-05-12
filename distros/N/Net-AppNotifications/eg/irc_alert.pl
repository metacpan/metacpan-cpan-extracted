use strict;
use warnings;
use AnyEvent;
use AnyEvent::IRC::Client;
use Net::AppNotifications;
use Carp;

## A basic script that connects to irc and send notifications
## each time a message matching a regexp is send to the chan

## the regexp triggering a notification
my $re   = qr/(appnotification|iphone|omg|alert|ddos|dos)/i;
my $nick = 'appnotifications';

my $key    = shift or croak "usage: $0 <key> <irc server> <chan>";
my $server = shift || "localhost";
my $chan   = shift || "#test";

unless ($chan =~ /^#/) {
    warn "Channel must have a #";
    $chan = "\#$chan";
}

my ($host, $port) = ($server =~ /^(.+):(\d+)$/);
$host ||= $server;
$port ||= 6667;

my $con = AnyEvent::IRC::Client->new;
my $c = AnyEvent->condvar;
my $timer;

my $notifier = Net::AppNotifications->new(key => $key);

$con->reg_cb(registered => sub { print "Hit ^C to interrupt\n"; });
$con->reg_cb(disconnect => sub { print "I'm out!\n"; $c->broadcast });
#use YAML;
#$con->reg_cb(read => sub { warn Dump $_[1] });
$con->reg_cb(
    publicmsg => sub {
        my $msg = $_[2]->{params}[1];
        return unless $msg;
        if ($msg =~ $re) {
            $notifier->send(
                message    => "IRC $chan: $msg",
                on_success => sub { print "delivered\n" },
                on_error   => sub { print "NOT delivered\n" },
            );
        }
    },
);
$con->send_srv("JOIN", $chan);
#$con->send_chan(
#   $chan,
#   "PRIVMSG",
#   $chan,
#   "Hi, i'm a bot sending iPhone notifications!",
#);

$con->connect($host, $port, { nick => $nick });
$c->wait;
$con->disconnect;
