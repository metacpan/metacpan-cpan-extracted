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
use Tapper::Config;

# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = FATAL, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);

BEGIN { use_ok('Tapper::PRC::Testcontrol') }

my $testcontrol = Tapper::PRC::Testcontrol->new;
$testcontrol->cfg->{report_server}   = Tapper::Config->subconfig->{report_server};
$testcontrol->cfg->{report_api_port} = Tapper::Config->subconfig->{report_api_port};

# No accidental ostore usage during testing
delete Tapper::Config->subconfig->{ostore};

my $upload_dir = Tapper::Config->subconfig->{paths}{output_dir}."/4";
if (not -e $upload_dir) {
        $testcontrol->makedir("$upload_dir/install"); # inherited from Tapper::Base;
}
open my $fh, ">", "$upload_dir/install/prove" or die "Can not create upload file: $!";
print $fh "content\n";
close $fh;

my $retval;

my $pid;
$pid = fork();
if ($pid == 0) {
        sleep(2); # bad and ugly to prevent race condition
        $ENV{TAPPER_OUTPUT_PATH} = $upload_dir;
        $retval = $testcontrol->upload_files(23);

        # Can't make this a test since the test counter isn't handled correctly after fork
        die $retval if $retval;
        exit 0;
} else {
        my $server = IO::Socket::INET->new(Listen    => 5,
                                           LocalPort => Tapper::Config->subconfig->{report_api_port});
        ok($server, 'create socket');
        my $content;
        eval {
                $SIG{ALRM} = sub { 
                    die ("timeout of 5 seconds reached while waiting for file upload test.")
                };
                alarm(5);
                my $msg_sock = $server->accept();
                while (my $line = <$msg_sock>) {
                        $content .= $line;
                }
                alarm(0);
        };
        is ($@, '', 'Getting data from file upload');

        my $msg = "#! upload 23 install/prove plain\ncontent\n";
        is($content, $msg, 'File content from upload');

        waitpid($pid,0);
}

done_testing();
