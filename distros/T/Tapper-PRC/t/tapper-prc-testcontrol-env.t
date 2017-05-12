#! /usr/bin/env perl

use strict;
use warnings;

use Test::MockModule;
use YAML::Syck;

use Log::Log4perl;

use Test::More;
use Test::Deep;
use Test::MockModule;

use File::Temp;

# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = FATAL, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


BEGIN { use_ok('Tapper::PRC::Testcontrol'); }

my $testcontrol = Tapper::PRC::Testcontrol->new();
my $output_dir = File::Temp::tempdir( CLEANUP => 1 );
$testcontrol->cfg({test_run => 1234,
                   mcp_server => 'localhost',
                   report_server => 'localhost',
                   hostname => 'localhost',
                   reboot_counter => 0,
                   max_reboot => 0,
                   guest_number => 0,
                   syncfile => '/dev/null', # just to check if set correctly in ENV
                   paths => {output_dir => $output_dir},
                   testprogram_list => [{ program             => '/bin/true',
                                          chdir               => "/my/chdir/affe/zomtec",
                                          environment         => { AFFE => "ZOMTEC"},
                                          runtime             => 72000,
                                          timeout_testprogram => 129600,
                                          parameters          => ['--tests', '-v'],
                                        }],
                  });
is($testcontrol->cfg->{test_run}, 1234, 'Setting attributes');
my $retval;

# Mock actual execution of testprogram
my @execute_options;
my $mock_testcontrol = Test::MockModule->new('Tapper::PRC::Testcontrol');
$mock_testcontrol->mock('testprogram_execute',sub{(undef, @execute_options) = @_;return 0});
$mock_testcontrol->mock('mcp_inform',sub{return 0;});
$retval = $testcontrol->testprogram_execute();
is($retval, 0, 'Mocking testprogram_execute');

$retval = $testcontrol->control_testprogram();
is($retval, 0, 'Running control_testprogram');

is($execute_options[0]{chdir}, "/my/chdir/affe/zomtec", "providing chdir");
is($execute_options[0]{environment}{AFFE}, "ZOMTEC", "providing environment");



$testcontrol->cfg({test_run => 1234,
                   mcp_server => 'localhost',
                   report_server => 'localhost',
                   hostname => 'localhost',
                   reboot_counter => 0,
                   max_reboot => 0,
                   guest_number => 0,
                   syncfile => '/dev/null', # just to check if set correctly in ENV
                   paths => {output_dir => $output_dir,
                             sync_path => 't/executables/',
                             testprog_path  => 't/executables/',
                            },
                   testprogram_list => [{ program             => 'env',
                                          runtime             => 72,
                                          timeout_testprogram => 120,
                                        }],
                  });

$mock_testcontrol->unmock('testprogram_execute');
$retval = $testcontrol->control_testprogram();

ok(-e "$output_dir/1234/test/env.stdout", 'Test output file exists');

my ($sync_path_in_env);
open my $fh, '<', "$output_dir/1234/test/env.stdout" or die "Can not open optput file $output_dir/1234/test/env.stdout: $!";
while (my $line = <$fh>) {
        if ($line =~ /^TAPPER_SYNC_PATH=(.+)/) {
                $sync_path_in_env = $1;
        }
};

is($sync_path_in_env, 't/executables/', '$SYNC_PATH set in environment') ;

done_testing();
