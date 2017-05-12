#! /usr/bin/env perl

use strict;
use warnings;

use File::Temp qw/ tempdir /;

use Log::Log4perl;
use Cwd 'getcwd';
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

my $tempdir = tempdir( CLEANUP => 1 );
$ENV{TAPPER_OUTPUT_PATH} = $tempdir;
my $server = IO::Socket::INET->new(Listen    => 5);
ok($server, 'create socket');

my $cfg = {paths         => {testprog_path => getcwd().'/'} ,
           hostname      => 'testhost',
           test_run      => 735710,
           report_server => 'localhost',
           report_port   => $server->sockport
          };



my $testcontrol = Tapper::PRC::Testcontrol->new(cfg => $cfg);
my $program = {program => 't/executables/ripley',
               capture => 'tap',
               argv    => ["1..2", "expected text"],
               out_dir => $tempdir.'/',
               };

my $pid=fork();
if ($pid==0) {
        close $server;
        diag "Sleep a bit to prevent timout race conditions...";
        sleep($ENV{TAPPER_SLEEPTIME} || 10);
        $testcontrol->testprogram_execute($program);
        exit 0;

} else {
        my $content;

        eval{
                my $timeout = 3 * ($ENV{TAPPER_SLEEPTIME} || 10);
                local $SIG{ALRM}=sub{die("timeout of $timeout seconds reached while waiting for test.");};
                alarm($timeout);
                my $msg_sock = $server->accept();
                print $msg_sock "Your report_id is 8888\n";
                while (my $line=<$msg_sock>) {
                        $content.=$line;
                }
                alarm(0);
        };
        is($@, '', 'Get state messages in time');

        waitpid($pid,0);

        is($content, '1..2
# Tapper-suite-name: ripley
# Tapper-machine-name: testhost
# Tapper-reportgroup-testrun: 735710
expected text
ok - No file appendix. May be the first iteration
', 'Upload TAP on behalf of testsuite (option capture => "tap")');
}

$pid=fork();
if ($pid==0) {
        close $server;
        diag "Sleep a bit to prevent timout race conditions...";
        sleep($ENV{TAPPER_SLEEPTIME} || 10);
        $testcontrol->testprogram_execute($program);
        exit 0;

} else {
        my $content;

        eval{
                my $timeout = 3 * ($ENV{TAPPER_SLEEPTIME} || 10);
                local $SIG{ALRM}=sub{die("timeout of $timeout seconds reached while waiting for test.");};
                alarm($timeout);
                my $msg_sock = $server->accept();
                print $msg_sock "Your report_id is 8888\n";
                while (my $line=<$msg_sock>) {
                        $content.=$line;
                }
                alarm(0);
        };
        is($@, '', 'Get state messages in time');

        waitpid($pid,0);

        is($content, '1..2
# Tapper-suite-name: ripley
# Tapper-machine-name: testhost
# Tapper-reportgroup-testrun: 735710
expected text
ok - If we find this, capturing works with outfile name appendices
', 'Upload TAP on behalf of testsuite (option capture => "tap")');
}


done_testing;
