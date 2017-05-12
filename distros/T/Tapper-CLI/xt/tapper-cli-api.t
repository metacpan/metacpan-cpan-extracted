#! /usr/bin/env perl

use strict;
use warnings;

use Cwd;
use Test::More;
use File::Temp 'tempfile';
use Tapper::CLI::Testrun;
use Tapper::CLI::Testrun::Command::list;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;
use File::Slurp 'slurp';
use Tapper::Reports::API::Daemon;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

# ____________________ START SERVER ____________________

$ENV{MX_DAEMON_STDOUT} = getcwd."/test-tapper_reports_api_daemon_stdout.log";
$ENV{MX_DAEMON_STDERR} = getcwd."/test-tapper_reports_api_daemon_stderr.log";

my $grace_period = 5;
my $port = Tapper::Config->subconfig->{report_api_port};
my $api  = new Tapper::Reports::API::Daemon (
                                              basedir => getcwd,
                                              pidfile => getcwd.'/test-tapper-reports-api-daemon-test.pid',
                                              port    => $port,
                                             );
$api->run("start");
sleep $grace_period;

# ____________________ UPLOAD/DOWNLOAD ____________________

my $file     = 't/dummy-attachment.txt';
my $upload   = `$^X -Ilib bin/tapper-api upload   --reportid 23 --file "$file"`;
my $download = `$^X -Ilib bin/tapper-api download --reportid 23 --file "$file"`;
my $expected = slurp $file;
is ($download, $expected, "downloaded file is uploaded file");

# ____________________ UPLOAD TWICE / DOWNLOAD 2ND ____________________

# one file, (used twice)
my ($FH, $file1) = tempfile( UNLINK => 1 );

# first
my $content1 = slurp $file;
print $FH $content1;
close $FH;
$upload = `$^X -Ilib bin/tapper-api upload   --reportid 23 --file "$file1"`;

# second
my $content2 = $content1."ZOMTEC";
open $FH, ">", $file1 or die "Cannot write $file1";
print $FH $content2;
close $FH;
$upload = `$^X -Ilib bin/tapper-api upload   --reportid 23 --file "$file1"`;

# download first
$expected = $content1;
$download = `$^X -Ilib bin/tapper-api download --reportid 23 --file "$file1"`;
is ($download, $expected, "downloaded 1st file is uploaded file");

# downloaded first with explicit index
$expected = $content1;
$download = `$^X -Ilib bin/tapper-api download --reportid 23 --file "$file1" --index=0`;
is ($download, $expected, "downloaded 1st file with explicit index is uploaded file");

$expected = $content2;
$download = `$^X -Ilib bin/tapper-api download --reportid 23 --file "$file1" --nth=1`;
is ($download, $expected, "downloaded 2nd file is uploaded file");

# ____________________ CLOSE SERVER ____________________

#sleep 60;
$api->run("stop");

done_testing();
