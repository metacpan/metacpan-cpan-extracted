use strict;
use warnings;
use POSIX ":sys_wait_h";

package Tapper::Remote::Net::Test;

use Moose;

extends 'Tapper::Base';

has cfg => (is      => 'rw',
            default => sub { {} },
           );
sub BUILD
{
        my ($self, $config) = @_;
        $self->{cfg}=$config;
}

with 'Tapper::Remote::Net';

package main;

use Test::More;
use Test::MockModule;
use File::Temp 'tempdir';

use Log::Log4perl;

BEGIN {
        use_ok('Tapper::Remote::Net');
 }



my $string = "
log4perl.rootLogger           = FATAL, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


my $server = IO::Socket::INET->new(Listen    => 5);
ok($server, 'create socket');

my $tempdir = tempdir(CLEANUP => 1);

my $config = {
              mcp_host => 'localhost',
              mcp_port => $server->sockport(),
              testrun_id => 1,
              paths => {output_dir => $tempdir },
             };



my $net = Tapper::Remote::Net::Test->new($config);


my $report = {
              tests => [
                        {error => 1, test  => 'First test'},
                        { test  => 'Second test' },
                       ],
              headers => {
                          First_header => '1',
                          Second_header => '2',
                         },
             };
my $message = $net->tap_report_create($report);
like($message, qr(# First_header: 1), 'First header in tap_report_create');
like($message, qr(# Second_header: 2), 'Second header in tap_report_create');
like($message, qr(not ok 1 - First test\nok 2 - Second test), 'Tests in tap_report_create');

my $retval = $net->mcp_inform('start-install');

# testing message sending is more complex; ignore it for now
is($retval, 0, 'No error in writing status message');

$retval = $net->log_to_file('install');
is($retval, 0, 'Log_to_file execution');
ok(-e "$tempdir/1/install/Tapper.stdout", 'File created by log_to_file');
diag $tempdir;


done_testing;
