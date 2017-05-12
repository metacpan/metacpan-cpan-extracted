# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ser-BinRPC.t'

#########################

# Automatic test requires running SER configured using ser.cfg
# Consider rights to /tmp/ser_ctl UNIX socket (root???)

# change 'tests => 1' to 'tests => last_test_to_print';

use Socket;
use Test::More tests => 45;
BEGIN { 
use_ok('Ser::BinRPC')
};

my $conn = Ser::BinRPC->new();
isa_ok($conn, 'Ser::BinRPC');
can_ok($conn, qw(parse_connection_string open close command));
is($conn->{sock_domain}, PF_UNIX);
ok($conn->parse_connection_string('unix:/test'));
is($conn->{unix_sock}, '/test');
ok(! $conn->parse_connection_string('blabla'));
ok($conn->parse_connection_string('udp'));
ok($conn->parse_connection_string('udp:1.2.3.4'));
is($conn->{sock_domain}, PF_INET);
is($conn->{remote_host}, '1.2.3.4');
is($conn->{remote_port}, 2049);
ok($conn->parse_connection_string('udp:1.2.3.4:'));
is($conn->{remote_port}, 2049);
ok($conn->parse_connection_string('udp:1.2.3.4:456'));
is($conn->{remote_port}, 456);
undef $conn;

$conn = Ser::BinRPC->new();
is($conn->{sock_domain}, PF_UNIX);
$conn->{verbose} = 1;
is($conn->{verbose}, 1);
$conn->{verbose} = 0;
is($conn->{verbose}, 0);
is($conn->{unix_sock}, '/tmp/ser_ctl');

my @ss = ('unix', 'udp', 'tcp');
for (my $i=0; $i<=$#ss; $i++) {
	ok($conn->parse_connection_string($ss[$i]));
	ok($conn->open());
	ok($conn->command('core.uptime'));
	ok($conn->command('core.ps'));
	$conn->close;
};

$conn->parse_connection_string('udp');
$conn->open();
my @res;
my $retcode;
$retcode = $conn->command('core.pwd', [], \@res);
#$conn->print_result(\*STDERR, \@res);
is($retcode, 1);
is($res[0], '/');

$retcode = $conn->command('core.uptime', [], \@res);
#$conn->print_result(\*STDERR, \@res);
is($retcode, 1);
ok($res[0]->{'uptime'} > 10);
$retcode = $conn->command('core.ps', [], \@res);
#$conn->print_result(\*STDERR, \@res);
is($retcode, 1);
is($res[1], 'attendant');

$retcode = $conn->command('XXXX', [], \@res);
#$conn->print_result(\*STDERR, \@res);
is($retcode, -1);
is($res[0], 500);
is($res[1], 'command XXXX not found');

$retcode = $conn->command('core.prints', ['TEXT'], \@res);
#$conn->print_result(\*STDERR, \@res);
is($retcode, 1);
is($res[0], 'TEXT');

$retcode = $conn->command('core.prints', ['s:12345'], \@res);
#$conn->print_result(\*STDERR, \@res);
is($retcode, 1);
is($res[0], '12345');


$conn->close;

