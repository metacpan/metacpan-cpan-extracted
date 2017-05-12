#! /usr/bin/env perl

use strict;
use warnings;

use Test::Fixture::DBIC::Schema;
use YAML::Syck;

use Tapper::Config;
use Tapper::MCP::Child;
use Tapper::Model 'model';
use Tapper::Schema::TestTools;

use Socket;
use Sys::Hostname;
use Test::Deep;
use Test::MockModule;
use Test::More;

BEGIN { use_ok('Tapper::MCP::Config'); }


# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = PatternLayout
# date package category - message in  last 2 components of filename (linenumber) newline
log4perl.appender.root.layout.ConversionPattern = %d %p %c - %m in %F{2} (%L)%n";
Log::Log4perl->init(\$string);


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


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_autoinstall.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $producer = Tapper::MCP::Config->new(1);
isa_ok($producer, "Tapper::MCP::Config", 'Producer object created');

my $config = $producer->create_config();
is(ref($config),'HASH', 'Config created');


my $tapper_host = Sys::Hostname::hostname();
my $packed_ip    = gethostbyname($tapper_host);
fail("Can not get an IP address for tapper_host ($tapper_host): $!") if not defined $packed_ip;

my $tapper_ip   = inet_ntoa($packed_ip);

ok(defined $config->{installer_grub}, 'Grub for installer set');
is($config->{installer_grub},
   "title opensuse 11.2\n".
   "kernel /tftpboot/kernel autoyast=bare.cfg tapper_ip=$tapper_ip tapper_port=11337 testrun=1 tapper_host=$tapper_host tapper_environment=test\n".
   "initrd /tftpboot/initrd\n",
   'Expected value for installer grub config');





#''''''''''''''''''''''''''''''''''''''''''''#
# When autoinstall started the installation  #
# MCP is supposed to provide a new grub file #
# for starting from hard disc.               #
# The following test checks whether this     #
# file is created correctly.                 #
#''''''''''''''''''''''''''''''''''''''''''''#
my $grubtext;
my $timeout = Tapper::Config->subconfig->{times}{boot_timeout};

my $mock_net = new Test::MockModule('Tapper::MCP::Net');
$mock_net->mock('reboot_system',sub{return 0;});
$mock_net->mock('upload_files',sub{return 0;});
$mock_net->mock('write_grub_file',sub{(undef, undef, $grubtext) = @_;return 0;});
$mock_net->mock('hw_report_create',sub{return (0, 'text');});



my $mock_inet = new Test::MockModule('IO::Socket::INET');
$mock_inet->mock('new', sub{my $inet = bless {sockport => sub {return 12;}}; return $inet});

my $mock_child = Test::MockModule->new('Tapper::MCP::Child');
$mock_net->mock('hw_report_create',sub{return (0, 'text');});

my $message = model('TestrunDB')->resultset('Message')->new
  ({
    message => {state => 'start-install'},
    testrun_id => 1,
   });
$message->insert;

$mock_child->mock('tap_report_away', sub{ return 0});
$mock_child->mock('upload_files', sub{ return 0});


my $testrun    = 1;
my $child      = Tapper::MCP::Child->new($testrun);

my $retval = $child->runtest_handling();
is ($grubtext, "timeout 2

title Boot from first hard disc
\tchainloader (hd0,1)+1
",
    'Grubfile written');

done_testing();
