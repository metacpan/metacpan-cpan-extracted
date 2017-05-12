#!/usr/bin/env perl
#doc
use strict;
use warnings;

# get rid of warnings
use Class::C3;
use MRO::Compat;
use Log::Log4perl;
use Test::Fixture::DBIC::Schema;
use Test::MockModule;

use Tapper::Config;
use Tapper::MCP;
use Tapper::MCP::Child;
use Tapper::MCP::Info;
use Tapper::Model 'model';
use Tapper::Schema::TestTools;
use YAML::Syck 'LoadFile';


use Test::More;

sub closure
{
        my ($file) = @_;
        my $i=0;
        my @data = LoadFile($file);
        return sub{my ($self, $file) = @_; return $data[$i++]};
}



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
#    Mock testrun setup functions    #
#                                    #
#''''''''''''''''''''''''''''''''''''#
my $mock_net = Test::MockModule->new('Tapper::MCP::Net');
$mock_net->mock('reboot_system',sub{return 0;});
$mock_net->mock('upload_files',sub{return 0;});
$mock_net->mock('write_grub_file',sub{return 0;});
$mock_net->mock('hw_report_send',sub{return 0;});
my $mock_conf = Test::MockModule->new('Tapper::MCP::Config');
$mock_conf->mock('write_config',sub{return 0;});




my @tap_reports;
my $mock_child = Test::MockModule->new('Tapper::MCP::Child');
$mock_child->mock('tap_report_away', sub { my (undef, $new_tap_report) = @_; push @tap_reports, $new_tap_report; return (0,0)});


my $child      = Tapper::MCP::Child->new(4);
my $retval;


my $mcp_info=Tapper::MCP::Info->new();
$mcp_info->add_prc(0, 5);
$mcp_info->add_testprogram(0, {timeout => 15, name => "foo", argv => ['--bar']});
$mcp_info->set_max_reboot(0, 2);
$child->mcp_info($mcp_info);



my $pid=fork();
if ($pid==0) {
        sleep(2); #bad and ugly to prevent race condition
        open my $fh, "<","t/command_files/quit_during_installation.txt" or die "Can't open commands file for quit test:$!";

        # get yaml and dump it instead of reading from file directly allows to have multiple messages in the file without need to parse seperators
        my $closure = closure($fh);
        while (my $yaml = &$closure()) {
                my $message = model('TestrunDB')->resultset('Message')->new({testrun_id => 4, message =>  $yaml});
                $message->insert;
        }
        exit 0;
} else {
        eval{
                $SIG{ALRM}=sub{die("timeout of 70 seconds reached while waiting for 'quit in installer' test.");};
                alarm(70);
                $child->runtest_handling();
        };
        is($@, '', 'Get messages in time');
        waitpid($pid,0);
}

# TAP report 0 is hw report
is($tap_reports[1], "1..1
# Tapper-reportgroup-testrun: 4
# Tapper-suite-name: Topic-Software
# Tapper-suite-version: $Tapper::MCP::VERSION
# Tapper-machine-name: bullock
# Tapper-section: MCP overview
# Tapper-reportgroup-primary: 1
not ok 1 - Testrun cancelled during state 'installing': killed by admin
# killed by admin
", 'Report for quit during installation');


@tap_reports=();
$pid=fork();
if ($pid==0) {
        sleep(2); #bad and ugly to prevent race condition
        open my $fh, "<","t/command_files/quit_during_test.txt" or die "Can't open commands file for quit test:$!";

        # get yaml and dump it instead of reading from file directly allows to have multiple messages in the file without need to parse seperators
        my $closure = closure($fh);
        while (my $yaml = &$closure()) {
                my $message = model('TestrunDB')->resultset('Message')->new({testrun_id => 4, message =>  $yaml});
                $message->insert;
        }
        exit 0;
} else {
        eval{
                $SIG{ALRM}=sub{die("timeout of 70 seconds reached while waiting for 'quit in installer' test.");};
                alarm(70);
                $child->runtest_handling();
        };
        is($@, '', 'Get messages in time');
        waitpid($pid,0);
}

# TAP report 0 is hw report
is($tap_reports[1], "1..2
# Tapper-reportgroup-testrun: 4
# Tapper-suite-name: Topic-Software
# Tapper-suite-version: $Tapper::MCP::VERSION
# Tapper-machine-name: bullock
# Tapper-section: MCP overview
# Tapper-reportgroup-primary: 1
ok 1 - Installation finished
not ok 2 - Testrun cancelled during state 'reboot_test': killed by admin
# killed by admin
", 'Report for quit during installation');



done_testing();
