use strict;
use warnings;
use Find::Lib '../lib';
use Net::AppNotifications;
use AnyEvent::Superfeedr;

# connect to Superfeedr with <jid> and <pass>
# and send up to 10 notifications to iPhone using appnotifications.com
# configured with <key>.
#
# To get something to stream, we subscribe <jid> with friendfeed's public
# timeline.

my @subs = qw(
    http://friendfeed.com/public?format=atom
);

my ($key, $jid, $pass) = @ARGV;

die "usage: $0 <key> <jid> <pass>"
    unless $key && $jid;

my $end = AnyEvent->condvar;
my $n   = 0;

my $notifier   = Net::AppNotifications->new(key => $key);
my $superfeedr; $superfeedr = AnyEvent::Superfeedr->new(
    jid => $jid,
    password => $pass,
    subscription => {
        interval => 60,
        cb => sub { [ shift @subs ] },
    },
    on_notification => sub { 
        my $notification = shift;

        for my $entry ($notification->entries) {
            my $title = Encode::decode_utf8($entry->title);
            $title =~ s/\s+/ /gs;

            my $l = length $title;
            my $max = 50;
            if ($l > $max) {
                substr $title, $max - 3, $l - $max + 3, '...';
            }

            my $message = sprintf "~ %-50s\n", $title;
            $notifier->send(
                message    => $message,
                on_success => sub { print "Delivered $message\n" },
                on_error   => $end,
            );

            ## achevons la bete
            $end->send if $n++ > 10;
        }
    },
);

$end->recv;
