#! /usr/bin/env perl

use strict;
use warnings;

use Test::MockModule;
use File::Temp;
use YAML::Syck;
use Data::Dumper;

use Tapper::Config;

use Test::More;


# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = FATAL, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


BEGIN { use_ok('Tapper::PRC::Testcontrol'); }
my $tapper_cfg = Tapper::Config->subconfig;

my $prc = Tapper::PRC::Testcontrol->new();

my $output_dir = File::Temp::tempdir( CLEANUP => 1 );
my $config = {
              test_run => 1234,
              mcp_server => 'localhost',
              mcp_port   => $tapper_cfg->{mcp_port},
              report_server => 'localhost',
              hostname => 'localhost',
              reboot_counter => 0,
              max_reboot => 0,
              guest_number => 0,
              syncfile => '/dev/null', # just to check if set correctly in ENV
              paths => {output_dir => $output_dir, testprog_path => '.'},
              testprogram_list => [{
                                    program => 't/files/exec/sleep.sh',
                                    runtime => 2,
                                    timeout_testprogram => 3,
                                    parameters => ['5'],
                                   },
                                  {
                                    program => 't/files/exec/sleep.sh',
                                    runtime => 2,
                                    timeout_testprogram => 5,
                                    parameters => ['1'],
                                   }
                                  ],
             };
my $mock_config = Test::MockModule->new('Tapper::Remote::Config');
$mock_config->mock('get_local_data',sub{return $config});

my $pid=fork();
if ($pid==0) {
        sleep(2); #bad and ugly to prevent race condition
        $prc->run();

        exit 0;
} else {
        my $server = IO::Socket::INET->new(Listen    => 5,
                                           LocalPort => $tapper_cfg->{mcp_port});
        ok($server, 'create socket');
        my @content;
        eval{
                $SIG{ALRM}=sub{die("timeout\n");};
                alarm(15);

        MESSAGE:
                while (1) {
                        my $content;
                        my $msg_sock = $server->accept();
                        while (my $line=<$msg_sock>) {
                                $content.=$line;
                        }
                        if ($content =~ m|GET /(.+) HTTP/1.0|g) {
                                my %params    = split("/", $1);
                                push @content, \%params;
                                last MESSAGE if $params{state} eq 'end-testing';
                        } else {
                                fail "Content is not HTTP";
                        }
                }
                alarm(0);
        };
        is($@, '', 'Getting data from file upload');

        is($content[2]->{state}, 'end-testprogram', 'Continue testing after timeout in first testprogram');

        waitpid($pid,0);
}

done_testing();
