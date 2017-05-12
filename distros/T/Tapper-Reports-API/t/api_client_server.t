#! /usr/bin/env perl

use 5.010;
use strict;
use warnings;

BEGIN {
        use Class::C3;
        use MRO::Compat;
}

use Cwd;
use Test::More;
use Data::Dumper;
use Tapper::Config;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Tapper::Reports::API::Daemon;
use File::Slurp 'slurp';

# ----- Prepare test db -----

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $port = Tapper::Config->subconfig->{report_api_port};

my $EOFMARKER    = "MASONTEMPLATE".$$;
my $payload_file = 't/test_payload.txt';
my $payload;
my $expected_file;
my $grace_period = 5;
my $expected;
my $filecontent;
my $res;
my $sock;
my $success;

# ____________________ START SERVER ____________________

$ENV{MX_DAEMON_STDOUT} = getcwd."/test-tapper_reports_api_daemon_stdout.log";
$ENV{MX_DAEMON_STDERR} = getcwd."/test-tapper_reports_api_daemon_stderr.log";

my $api = new Tapper::Reports::API::Daemon (
                                             basedir => getcwd,
                                             pidfile => getcwd.'/test-tapper-reports-api-daemon-test.pid',
                                             port    => $port,
                                            );
$api->run("start");
sleep $grace_period;


# ____________________ UPLOAD ____________________

# Client communication

my $dsn = Tapper::Config->subconfig->{test}{database}{TestrunDB}{dsn};
my $testrundb_schema = Tapper::Schema::TestrunDB->connect($dsn,
                                                           Tapper::Config->subconfig->{test}{database}{TestrunDB}{username},
                                                           Tapper::Config->subconfig->{test}{database}{TestrunDB}{password},
                                                           {
                                                            ignore_version => 1
                                                           }
                                                          );

$payload    = slurp $payload_file;
$sock = IO::Socket::INET->new( PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp', ReuseAddr => 1) or die $!;
$success = $sock->print( "#! upload 23 $payload_file\n".$payload );
close $sock;

# Check DB content

# wait, because the server is somewhat slow until the upload is visible in DB
sleep $grace_period;

is( $testrundb_schema->resultset('ReportFile')->count, 1,  "new reportfile count" );

eval {
        $filecontent = $testrundb_schema->resultset('ReportFile')->search({})->first->filecontent;
        $expected    = slurp $payload_file;
        is( $filecontent, $expected, "upload");
};

# ------------------------------ upload again, slightly different payload --------------------

$sock = IO::Socket::INET->new( PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp', ReuseAddr => 1) or die $!;
$success = $sock->print( "#! upload 23 $payload_file\n".$payload."ZOMTEC" );
close $sock;

# Check DB content

# wait, because the server is somewhat slow until the upload is visible in DB
sleep $grace_period;

is( $testrundb_schema->resultset('ReportFile')->count, 2,  "newer reportfile count" );

# ____________________ DOWNLOAD ____________________

# Client communication

# ----- download first upload before -----
$expected = slurp $payload_file;
$sock = IO::Socket::INET->new( PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp', ReuseAddr => 1) or die $!;
$success = $sock->print( "#! download 23 $payload_file\n" );
{ local $/; $res = <$sock> }
close $sock;
is($res, $expected, "same file downloaded");

# ----- download first upload before, but via specify no report_id -----
$expected = slurp $payload_file;
$sock = IO::Socket::INET->new( PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp', ReuseAddr => 1) or die $!;
$success = $sock->print( "#! download 0 $payload_file\n" );
{ local $/; $res = <$sock> }
close $sock;
is($res, $expected, "same file downloaded via report_id 0");

# ---------- check second uploaded file ----------
$expected  = slurp $payload_file;
$expected .= "ZOMTEC";
$sock = IO::Socket::INET->new( PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp', ReuseAddr => 1) or die $!;
$success = $sock->print( "#! download 23 $payload_file 1\n" );
{ local $/; $res = <$sock> }
close $sock;
is($res, $expected, "second file downloaded");

$sock = IO::Socket::INET->new( PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp', ReuseAddr => 1) or die $!;
$success = $sock->print( "#! download 0 $payload_file 1\n" );
{ local $/; $res = <$sock> }
close $sock;
is($res, $expected, "second file downloaded via report_id 0 and slice");

# ____________________ MASON ____________________

# Client communication
$payload_file  = "t/perfmon_tests_planned.mas";
$expected_file = "t/perfmon_tests_planned.expected";
$expected      = slurp $expected_file;
$sock = IO::Socket::INET->new( PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp', ReuseAddr => 1) or die $!;
# EOF marker with no whitespace after "<<"
$success = $sock->print( "#! mason <<$EOFMARKER\n".slurp($payload_file)."$EOFMARKER\n" );
{ local $/; $res = <$sock> }
close $sock;
is( $res, $expected, "mason eof marker with no whitespace");

$sock = IO::Socket::INET->new( PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp', ReuseAddr => 1) or die $!;
# EOF marker with whitespace after "<<"
$success = $sock->print( "#! mason << $EOFMARKER\n".slurp($payload_file)."$EOFMARKER\n" );
{ local $/; $res = <$sock> }
close $sock;
is( $res, $expected, "mason eof marker with whitespace");


# ____________________ TT  ____________________

# Client communication
$payload_file  = "t/perfmon_tests_planned.tt";
$sock = IO::Socket::INET->new( PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp', ReuseAddr => 1) or die $!;
# EOF marker with no whitespace after "<<"
$success = $sock->print( "#! tt <<$EOFMARKER\n".slurp($payload_file)."$EOFMARKER\n" );
{ local $/; $res = <$sock> }
close $sock;
is( $res, $expected, "Template toolkit");

# ____________________ CLOSE SERVER ____________________

#sleep 60;
$api->run("stop");

done_testing();
