use strict;
use warnings;

use lib 't/lib';

use IO::Select;
use Perlbal::Test;
use Perlbal::Test::WebClient;

use Test::More tests => 12;

my $perlbal_port = new_port();
my $syslog_port = new_port();

$SIG{CHLD} = 'IGNORE';

use IO::Socket::INET;
my $syslogd = IO::Socket::INET->new(
    Proto       => 'udp',
    Type        => SOCK_DGRAM,
    LocalHost   => 'localhost',
    LocalPort   => $syslog_port,
    Blocking    => 0,
    Reuse       => 1,
) or die "failed to listen on udp $syslog_port: $!";
my $select = IO::Select->new($syslogd);

my $conf = qq{
LOAD Syslogger
LOAD TestPlugin

CREATE SERVICE fakeproxy
    SET role            = reverse_proxy
    SET listen          = 127.0.0.1:$perlbal_port

    SET syslog_host     = localhost
    SET syslog_port     = $syslog_port
    SET syslog_source   = localhost
    SET syslog_name     = explicit
    SET syslog_facility = 21
    SET syslog_severity = 5

    SET plugins         = Syslogger, TestPlugin
ENABLE fakeproxy
};

my $msock = start_server($conf);
ok($msock, 'perlbal started');

my $mgmt_port = mgmt_port();

my $wc = Perlbal::Test::WebClient->new;
$wc->server("127.0.0.1:$perlbal_port");
$wc->keepalive(1);
$wc->http_version('1.0');

my $resp = $wc->request({ host => "example.com", }, "foo/bar.txt");
ok($resp, "got a response");

is($resp->code, 200, "response code correct");

my @readable = $select->can_read(0.1);
if (ok(scalar(@readable), 'syslog got messages')) {
    my @msgs = <$syslogd>;
    if (is(scalar(@msgs), 7, 'syslog got right number of messages')) {
        like($msgs[0], qr/^<173>.*localhost explicit\[\d+\]: registering TestPlugin$/, 'logged Registering');
        like($msgs[1], qr/^<174>.*localhost explicit\[\d+\]: info message in plugin$/, 'logged info message');
        like($msgs[2], qr/^<171>.*localhost explicit\[\d+\]: error message in plugin$/, 'logged error message');
        like($msgs[3], qr/^<173>.*localhost explicit\[\d+\]: printing to stdout$/, 'logged via STDOUT');
        like($msgs[4], qr/^<173>.*localhost explicit\[\d+\]: printing to stderr$/, 'logged via STDERR');
        like($msgs[5], qr/^<174>.*localhost explicit\[\d+\]: beginning run$/, 'captured internal message');
        like($msgs[6], qr/^<173>.*localhost explicit\[\d+\]: handling request in TestPlugin$/, 'logged in request');
    }
}

1;
