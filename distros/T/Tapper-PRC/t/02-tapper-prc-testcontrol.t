#! /usr/bin/env perl

use strict;
use warnings;

use Test::MockModule;
use File::Temp qw/ :seekable /;
use YAML::Syck;

use Log::Log4perl;

use Test::More;

my $config_bkup = 't/files/tapper.backup';

# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = FATAL, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


BEGIN { use_ok('Tapper::PRC::Testcontrol'); }



my $mock_control = new Test::MockModule('Tapper::PRC::Testcontrol');
$mock_control->mock('nfs_mount', sub { return(0);});

my $mock_prc = new Test::MockModule('Tapper::PRC');
$mock_prc->mock('log_and_exec', sub { return(0);});


my $fh          = File::Temp->new();
my $config_file = $fh->filename;
system("cp",$config_bkup, $config_file) == 0 or die "Can't copy config file:$!";
$ENV{TAPPER_CONFIG} = $config_file;

my $server;
my @content;


my $pid=fork();
if ($pid==0) {
        diag "Sleep a bit to prevent timout race conditions...";
        sleep($ENV{TAPPER_SLEEPTIME} || 10);

        my $testcontrol = new Tapper::PRC::Testcontrol;
        $testcontrol->run();
        $testcontrol->run();
        exit 0;

} else {
        $server = IO::Socket::INET->new(Listen    => 5,
                                        LocalPort => 13377); # needs to be hard coded because config comed from
                                                             # local file in t/files/
        ok($server, 'create socket');
        eval{
                local $SIG{ALRM}=sub{die("timeout of 50 seconds reached while waiting for reboot test.");};
                alarm(3*($ENV{TAPPER_SLEEPTIME} || 0));
                my $msg_sock = $server->accept();
                while (my $line=<$msg_sock>) {
                        $content[0].=$line;
                }

                $msg_sock = $server->accept();
                while (my $line=<$msg_sock>) {
                        $content[1].=$line;
                }


                $msg_sock = $server->accept();
                while (my $line=<$msg_sock>) {
                        $content[2].=$line;
                }

                alarm(0);
        };
        is($@, '', 'Get state messages in time');
        waitpid($pid,0);

        my @msg = ({testrun_id => 1234, prc_number => 0, state => "start-testing"},
                   {testrun_id => 1234, prc_number => 0, state => 'reboot', count => 0, max_reboot => 2},
                   {testrun_id => 1234, prc_number => 0, state => 'reboot', count => 1, max_reboot => 2});

        for(my $i=0; $i < int @content; $i++){
                if ($content[$i] =~ m|GET /(.+) HTTP/1.0|g) {
                        my %params    = split("/", $1);
                        is_deeply(\%params, $msg[$i], "Reboot message #$i");
                } else {
                        fail "Content is not HTTP";
                }
        }
}

my $config = YAML::Syck::LoadFile($config_file) or die("Can't read config file $config_file: $!");
is ($config->{reboot_counter}, 2, "Writing reboot count back to config");

########################################################
#
# Test state messages for multiple test scripts
#
########################################################

$ENV{TAPPER_CONFIG} = "t/files/multitest.conf";

@content=();

$pid=fork();
if ($pid==0) {
        diag "Sleep a bit to prevent timout race conditions...";
        sleep($ENV{TAPPER_SLEEPTIME} || 10);

        my $testcontrol = new Tapper::PRC::Testcontrol;
        $testcontrol->run();
        exit 0;

} else {
        eval{
                local $SIG{ALRM}=sub{die("timeout of 50 seconds reached while waiting for multiple test scripts messages.");};
                alarm(50);
                my $msg_sock = $server->accept();
                while (my $line=<$msg_sock>) {
                        $content[0].=$line;
                }

                $msg_sock = $server->accept();
                while (my $line=<$msg_sock>) {
                        $content[1].=$line;
                }


                $msg_sock = $server->accept();
                while (my $line=<$msg_sock>) {
                        $content[2].=$line;
                }

                $msg_sock = $server->accept();
                while (my $line=<$msg_sock>) {
                        $content[3].=$line;
                }


                alarm(0);
        };
        is($@, '', 'Get state messages in time');
        waitpid($pid,0);

        my @msg = ({testrun_id => 1234, prc_number => 0, state => "start-testing"},
                   {testrun_id => 1234, prc_number => 0, state => "end-testprogram", testprogram => 0},
                   {testrun_id => 1234, prc_number => 0, testprogram => 1, state => "error-testprogram"},
                   {testrun_id => 1234, prc_number => 0, state => "end-testing"});

        for(my $i=0; $i < int @content; $i++){
                if ($content[$i] =~ m|GET /(.+) HTTP/1.0|g) {
                        my %params    = split("/", $1);

                        # error msg depends on language setting, thus we don't check it, in case it exists
                        delete $params{error} if $params{error};
                        is_deeply(\%params, $msg[$i], "Message #$i");
                } else {
                        fail "Content is not HTTP";
                }
        }

}



done_testing;
