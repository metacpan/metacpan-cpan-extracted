# -*- perl -*-
use Test::More tests => 16;
use POSIX qw(pipe read write);
use strict;
use warnings;

# The tests for timeouts will only work
# reliably on unloaded machine

BEGIN {
    use_ok('Net::DBus::Reactor');
    use_ok('Net::DBus::Callback');
};


my $reactor = Net::DBus::Reactor->new();

my $started = $reactor->_now;
my $fired;
my $alarmed;

my $tid = $reactor->add_timeout(2000,
				Net::DBus::Callback->new(method => \&timeout, args => []),
				1);

$SIG{ALRM} = sub { $alarmed = 1 };

# Alarm just in case something goes horribly wrong
alarm 5;
$reactor->run;
alarm 0;

ok (!$alarmed, "not alarmed");
ok (defined $fired, "timeout fired");

# Timing is tricky, so just check a reasonble range
ok(($fired-$started) > 1900 &&
   ($fired-$started) < 3000, "timeout in range 1900->3000");

sub timeout {
    $fired = $reactor->_now;
    $reactor->shutdown;
}

$reactor->remove_timeout($tid);

my ($r1, $w1) = pipe;
my ($r2, $w2) = pipe;

write $w1, "1", 1;

my ($r1c, $w1c, $r2c, $w2c) = (0,0,0,0);
my $hookc = 0;

$reactor->add_read($r1, 
		   Net::DBus::Callback->new(method => \&do_r1));
$reactor->add_write($w1, 
		    Net::DBus::Callback->new(method => \&do_w1),
		    0);
$reactor->add_read($r2, 
		   Net::DBus::Callback->new(method => \&do_r2));
$reactor->add_write($w2, 
		    Net::DBus::Callback->new(method => \&do_w2),
		    0);

$reactor->add_hook(Net::DBus::Callback->new(method => \&hook));

$reactor->{running} = 1;
$reactor->step;

ok($r1c == 1, "read one byte a");
ok($r2c == 0, "not read one byte b");
ok($hookc == 1, "hook 1\n");

write $w1, "11", 2;
write $w2, "1", 1;

$reactor->{running} = 1;
$reactor->step;

ok($r1c == 2, "read 2 byte a");
ok($r2c == 1, "read one byte b");
ok($hookc == 2, "hook 2\n");

$reactor->{running} = 1;
$reactor->step;

ok($r1c == 3, "read 2 byte a");
ok($hookc == 3, "hook 3\n");

$reactor->toggle_write($w1, 1);
$reactor->toggle_write($w2, 1);

$reactor->{running} = 1;
$reactor->step;

ok($w1c == 1, "write 1 byte a");
ok($w2c == 1, "write 1 byte b");
ok($hookc == 4, "hook 4\n");


sub do_r1 {
    my $buf;
    $r1c += read $r1, $buf, 1;
}

sub do_w1 {
    $w1c += write $w1, "1", 1;
}

sub do_r2 {
    my $buf;
    $r2c += read $r2, $buf, 1;
}

sub do_w2 {
    $w2c += write $w2, "1", 1;
}

sub hook {
    $hookc++;
}
