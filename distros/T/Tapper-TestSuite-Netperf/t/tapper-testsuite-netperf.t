use Test::More;
use IO::Socket::INET;
use YAML;
use File::Temp 'tempdir';

use warnings;
use strict;

use Tapper::TestSuite::Netperf;
use Tapper::TestSuite::Netperf::Client;
use Tapper::TestSuite::Netperf::Server;

# bearable since it never really changes
my $logconf = '
log4perl.rootlogger             = ERROR, Screen
log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.layout = PatternLayout
# date package category - message in  last 2 components of filename (linenumber) newline
log4perl.appender.Screen.layout.ConversionPattern = %d %p %c - %m in %F{2} (%L)%n';
Log::Log4perl::init(\$logconf);

my $srv = Tapper::TestSuite::Netperf::Server->new;
isa_ok($srv,'Tapper::TestSuite::Netperf::Server');

my $client = Tapper::TestSuite::Netperf::Client->new;
isa_ok($client,'Tapper::TestSuite::Netperf::Client');

# start Netperf Server
my $pid = fork();
if ($pid == 0) {
        $srv->run();
        exit 0;
}


my $dir = tempdir( CLEANUP => 1 );
my @hosts=('localhost');
YAML::DumpFile("$dir/syncfile", [ @hosts ]);

my $receiver = IO::Socket::INET->new(Listen => 5);
ok($receiver, 'TAP receiver create');
$ENV{TAPPER_SYNC_FILE}     = "$dir/syncfile";
$ENV{TAPPER_REPORT_SERVER} = 'localhost';
$ENV{TAPPER_REPORT_PORT}   = $receiver->sockport();
$ENV{TAPPER_HOSTNAME}      = 'bascha';
$ENV{TAPPER_TESTRUN}       = 10;

# start report client
$pid = fork();
if ($pid == 0) {
        $receiver->close();
        sleep(2);  # poor man's process syncronisation
        my $retval = $client->run();
        exit 0;
}

my $content;
eval {
        local $SIG{ALRM}=sub{die("timeout of 30 seconds reached while waiting for reboot test.");};
        alarm(30);
        my $msg_sock = $receiver->accept();
        $msg_sock->say(20); # send report id
        while (my $line=<$msg_sock>) {
                $content .= $line;
        }

        alarm(0);
};
is($@, '', 'Get state messages in time');
waitpid($pid,0);

my $msg = qr(1..\d
# Tapper-reportgroup-testrun: 10
# Tapper-suite-name: Netperf
# Tapper-suite-version: $Tapper::TestSuite::Netperf::VERSION
# Tapper-machine-name: bascha
ok - Connect to peer
ok - benchmarks-custom
   ---
   bytes_per_second: [\d.]+
   length_send_buffer: [\d.]+
   length_receive_buffer: [\d.]+
   ...
);
like($content, $msg, 'Received message message');
#diag $content;

done_testing();
