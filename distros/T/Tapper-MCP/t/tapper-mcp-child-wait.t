#!/usr/bin/env perl

use strict;
use warnings;

# get rid of warnings
use Class::C3;
use IO::Socket::INET;
use MRO::Compat;
use Log::Log4perl;
use Test::Fixture::DBIC::Schema;
use Test::MockModule;
use YAML::Syck;

use Tapper::Model 'model';
use Tapper::Schema::TestTools;
use Tapper::Config;
use Tapper::MCP::Info;

# for mocking
use Tapper::MCP::Child;


use Test::More;

SKIP: {
        skip "For manual testing only", 1 unless $ENV{TAPPER_MANUAL_TESTING};

        sub msg_send
        {
                my ($yaml, $port) = @_;
                my $remote = IO::Socket::INET->new(PeerHost => 'localhost',
                                                   PeerPort => $port) or return "Can't connect to server:$!";
                print $remote $yaml;
                close $remote;
        }

        sub closure
        {
                my ($file) = @_;
                my $i=0;
                my @data = LoadFile($file);
                return sub{my ($self, $file) = @_; return $data[$i++]};
        }



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

        my $timeout = Tapper::Config->subconfig->{times}{boot_timeout};


        my $mock_net = new Test::MockModule('Tapper::MCP::Net');
        $mock_net->mock('reboot_system',sub{return 0;});
        $mock_net->mock('tap_report_send',sub{return 0;});
        $mock_net->mock('upload_files',sub{return 0;});
        $mock_net->mock('write_grub_file',sub{return 0;});

        my $mock_conf = new Test::MockModule('Tapper::MCP::Config');
        $mock_conf->mock('write_config',sub{return 0;});

        my $mock_inet     = new Test::MockModule('IO::Socket::INET');


        my $testrun    = 4;
        my $mock_child = Test::MockModule->new('Tapper::MCP::Child');
        my $child      = Tapper::MCP::Child->new($testrun);
        my $retval;



        #
        # reboot test
        #
        my $mcp_info=Tapper::MCP::Info->new();
        $mcp_info->add_prc(0, 300);
        $mcp_info->add_prc(1, 300);
        $mcp_info->add_testprogram(1, {timeout => 300, name => "foo", argv => ['--bar']});
        $child->mcp_info($mcp_info);

        my $server = IO::Socket::INET->new(Listen    => 5,
                                           LocalPort => 1337);
        ok($server, 'Create socket');

        my @content;
        eval{
                $SIG{ALRM}=sub{die("timeout of 5 seconds reached while waiting for file upload test.");};
                alarm(1200);
                $retval = $child->wait_for_testrun($server);
        };
        is($@, '', 'Get reboot messages in time');
        is_deeply($retval, [{'msg' => 'Test in PRC 0 started', 'error' => 0 },
                            {'msg' => 'Test in PRC 0 finished', 'error' => 0 },
                            {'msg' => 'Test in guest 1 started', 'error' => 0},
                            {'msg' => 'Testprogram 0 in guest 1', 'error' => 0 },
                            {'msg' => 'Test in guest 1 finished', 'error' => 0 },],
                  'Successful reboot test handling');
}
;
done_testing();


