# -*- perl -*-
use Test::More tests => 5;
use POSIX qw(pipe read write);
use strict;
use warnings;

# The tests for timeouts will only work
# reliably on unloaded machine

BEGIN {
    use_ok('Net::DBus::Reactor');
    use_ok('Net::DBus::Callback');
};

SKIP: {
skip "Time change fix requires root", 3 if $> != 0;

my $reactor = Net::DBus::Reactor->new();

my $started = $reactor->_now;
my $fired;
my $alarmed;

my $tid = $reactor->add_timeout(2000,
				Net::DBus::Callback->new(method => \&timeout, args => []),
				1);

my $time = time - 60*60*24;
system("date +%s -s \@$time");
$started=$reactor->_now;

$SIG{ALRM} = sub { $alarmed = 1 };

# Alarm just in case something goes horribly wrong
alarm 5;
$reactor->run;
alarm 0;

ok (!$alarmed, "not alarmed");
ok (defined $fired, "timeout fired");

# Timing is tricky, so just check a reasonble range
ok(($fired-$started) > 1900 &&
   ($fired-$started) < 3000, "timeout in range 1900->3000 ($fired-$started)");

sub timeout {
    $fired = $reactor->_now;
    $reactor->shutdown;
}

$reactor->remove_timeout($tid);

# restore back the system clock
$time = time + 60*60*24;
system("date +%s -s \@$time");
}
