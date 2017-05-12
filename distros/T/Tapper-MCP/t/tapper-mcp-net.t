#!/usr/bin/env perl

use strict;
use warnings;

use Class::C3;
use MRO::Compat;

use IO::Socket::INET;
use Log::Log4perl;
use POSIX ":sys_wait_h";
use Test::Fixture::DBIC::Schema;
use String::Diff;
use Sys::Hostname;
use YAML::Syck;
use Cwd;
use TAP::DOM;

use Tapper::MCP;
use Tapper::MCP::Net;
use Tapper::Schema::TestTools;

use Test::More;
use Test::Deep;

BEGIN { use_ok('Tapper::MCP::Net'); }

my $hw_send_testrun_id=23;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger                               = INFO, root
log4perl.appender.root                            = Log::Log4perl::Appender::Screen
log4perl.appender.root.layout                     = SimpleLayout";
Log::Log4perl->init(\$string);

my $srv = Tapper::MCP::Net->new;



SKIP:{
        skip "since environment variable TAPPER_RUN_CONSERVER_TEST is not set", 1 unless $ENV{TAPPER_RUN_CONSERVER_TEST};
        my $console = $srv->conserver_connect('bullock');
        isa_ok($console, 'IO::Socket::INET','Console connected');
        $srv->conserver_disconnect($console);
}



my ($error, $report) = $srv->hw_report_create($hw_send_testrun_id);

is ($error, 0, 'Successfull creation of hw_report');
is($report, "
TAP Version 13
1..2
# Tapper-Reportgroup-Testrun: 23
# Tapper-Suite-Name: Hardwaredb Overview
# Tapper-Suite-Version: $Tapper::MCP::VERSION
# Tapper-Machine-Name: dickstone
ok 1 - Getting hardware information
  ---
  cores: 2
  keyword: server
  mem: 4096
  vendor: AMD
  ...

ok 2 - Sending
", 'Hardware report layout');


done_testing();
