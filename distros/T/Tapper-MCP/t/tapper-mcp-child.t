#!/usr/bin/env perl

use strict;
use warnings;

# get rid of warnings
use Class::C3;
use MRO::Compat;
use Log::Log4perl;
use Test::Fixture::DBIC::Schema;
use Test::MockModule;
use YAML::Syck;
use Data::Dumper;

use Tapper::Schema::TestTools;
use Tapper::Config;

# for mocking
use Tapper::MCP::Child;
use Tapper::Model 'model';

use Test::More;



BEGIN { use_ok('Tapper::MCP::Child'); }

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


#''''''''''''''''''''''''''''''''''''#
#                                    #
#       Permanent mocking            #
#                                    #
#''''''''''''''''''''''''''''''''''''#


my $mock_net = new Test::MockModule('Tapper::MCP::Net');
$mock_net->mock('reboot_system',sub{return 0;});
$mock_net->mock('tap_report_send',sub{return 0;});
$mock_net->mock('upload_files',sub{return 0;});
$mock_net->mock('write_grub_file',sub{return 0;});

my $mock_conf = new Test::MockModule('Tapper::MCP::Config');
$mock_conf->mock('write_config',sub{return 0;});


my $testrun    = 4;
my $mock_child = Test::MockModule->new('Tapper::MCP::Child');
my $child      = Tapper::MCP::Child->new($testrun);
my $retval;

#''''''''''''''''''''''''''''''''''''#
#                                    #
#   Single functions tests           #
#                                    #
#''''''''''''''''''''''''''''''''''''#


#
# get_message()
#

eval {
        local $SIG{ALRM}=sub{die 'Timeout handling in get_message did not return in time'};
        alarm(5);
        $retval = $child->get_messages(1);
};
alarm(0);
is($@,'', 'get_messages returned after timeout');
die "All remaining tests may sleep forever if timeout handling in get_messages is broken"
  if $@ eq 'Timeout handling in get_messages did not return in time';
is($retval->count, 0, 'No message due to timeout in get_messages()');

my $message = model('TestrunDB')->resultset('Message')->new({testrun_id => 4, message =>  "state: start-install"});
$message->insert;

$retval = $child->get_messages(1);
is_deeply($retval->first->message, {state => 'start-install'}, 'get_messages() returns expected message');


#''''''''''''''''''''''''''''''''''''#
#                                    #
#   Full test through whole module   #
#                                    #
#''''''''''''''''''''''''''''''''''''#
my @tap_reports;
$mock_child->mock('tap_report_away', sub { my (undef, $new_tap_report) = @_; push @tap_reports, $new_tap_report; return (0,0)});



$retval =  $child->runtest_handling();
is($tap_reports[1], "1..1
# Tapper-reportgroup-testrun: 4
# Tapper-suite-name: Topic-Software
# Tapper-suite-version: $Tapper::MCP::VERSION
# Tapper-machine-name: bullock
# Tapper-section: MCP overview
# Tapper-reportgroup-primary: 1
not ok 1 - timeout hit while waiting for installation
", 'Detect timeout during installer booting');

@tap_reports = ();
$child      = Tapper::MCP::Child->new(113);
$retval =  $child->runtest_handling();
like($tap_reports[0],
          qr'1..1
# Tapper-reportgroup-testrun: 113
# Tapper-suite-name: Topic-Software
# Tapper-suite-version: \d+[.\d]+
# Tapper-machine-name: No hostname set
# Tapper-section: MCP overview
# Tapper-reportgroup-primary: 1
not ok 1 - Generating configs
# No architecture set for guest #1
', 'Reporting error in gen_config as TAP');


done_testing();
