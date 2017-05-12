#! /usr/bin/env perl

use strict;
use warnings;

use Test::MockModule;
use File::Temp qw/ :seekable /;
use YAML::Syck;

use Log::Log4perl;

use Test::More;
use Tapper::Config;
use Try::Tiny;

# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = FATAL, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


BEGIN { use_ok('Tapper::PRC::Testcontrol'); }

my $server;
my @content;

my $mock_prc = new Test::MockModule('Tapper::PRC::Testcontrol');
$mock_prc->mock('mcp_send', sub { my ($self, $message ) = @_; push @content, $message; return 0 });



my $config = {testrun => 1234,
              guests  => [
                          {
                           xen => 't/files/xen/guest_1.svm',
                          },
                          {
                           svm => 't/files/xen/guest_1.svm',
                          },
                         ]
             };


my $testcontrol = Tapper::PRC::Testcontrol->new(cfg => $config);
$ENV{PATH} = "t/executables/:$ENV{PATH}";
$testcontrol->guest_start();

my @expected = ({prc_number => 1, state => "error-guest", 'error' => 'create t/files/xen/guest_1.xl'},
                {prc_number => 2, state => 'error-guest', 'error' => 'create t/files/xen/guest_1.svm'},
               );

for my $i (0.. $#content){
        is_deeply($content[$i], $expected[$i], "Message for guest $i");
}

done_testing;
