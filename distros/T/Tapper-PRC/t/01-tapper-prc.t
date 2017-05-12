#! /usr/bin/env perl

use strict;
use warnings;

use Test::MockModule;
use YAML::Syck;

use Log::Log4perl;

use Test::More tests => 5;

# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = FATAL, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


BEGIN { use_ok('Tapper::PRC'); }


my $prc = new Tapper::PRC;

my ($error, $output) = $prc->log_and_exec('echo test');
is ($output,'test','log_and_exec, array mode');

$prc->{cfg} = {test_run => 1234, mcp_server => 'localhost', port => 11337};
my $pid=fork();
if ($pid==0) {
        sleep(2); #bad and ugly to prevent race condition
        $prc->mcp_inform({state => "test"});

        exit 0;
} else {
        my $server = IO::Socket::INET->new(Listen    => 5,
                                           LocalPort => 11337);
        ok($server, 'create socket');
        my $content;
        eval{
                $SIG{ALRM}=sub{die("timeout of 5 seconds reached while waiting for file upload test.");};
                alarm(5);
                my $msg_sock = $server->accept();
                while (my $line=<$msg_sock>) {
                        $content.=$line;
                }
                alarm(0);
        };
        is($@, '', 'Getting data from file upload');
        if ($content =~ m|GET /(.+) HTTP/1.0|g) {
                my %params    = split("/", $1);
                is_deeply(\%params, {
                                     state => 'test', testrun_id => 1234, prc_number => 0
                                    }, 'sending message to server, no virtualisation');
        } else {
                fail "Content is not HTTP";
        }

        waitpid($pid,0);
}
