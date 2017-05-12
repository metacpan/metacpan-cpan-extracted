use strict;
use warnings;
use Find::Lib '../lib';
use Net::AppNotifications;

my ($message, $email, $pass, $key);

if (@ARGV == 3) {
   ($email, $pass, $message) = @ARGV;
}
elsif (@ARGV == 2) {
    ($key, $message) = @ARGV;
}
else {
    die "usage: $0 [ <key> | <email> <pass> ] <message>";
}

my $notifier = Net::AppNotifications->new(
    key => $key,
    email => $email,
    pass => $pass,
);
$notifier->send($message);
