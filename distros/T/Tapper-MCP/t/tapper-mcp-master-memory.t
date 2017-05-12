#!/usr/bin/env perl

use strict;
use warnings;

# This file was created to be used with the debugger to find a memory leak in
# Tapper::MCP. It does not include any real test. Then again it walks through
# the whole MCP so its a good starting point to create a real test that tests
# all of MCP.


# get rid of warnings
use Class::C3;
use MRO::Compat;
use Log::Log4perl;
use Test::Fixture::DBIC::Schema;
use Test::MockModule;
use IO::Socket::INET;

use Tapper::Model 'model';
use Tapper::Schema::TestTools;

use Tapper::MCP::Master;

use IO::Handle;
autoflush STDOUT 1;
autoflush STDERR 1;

use Test::More tests => 1;
ok (1,'dummy');
__END__

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------
my $mockmaster = Test::MockModule->new('Tapper::MCP::Master');
# $mockmaster->mock('console_open',sub{use IO::Socket::INET;
#                                      my $sock = IO::Socket::INET->new(Listen=>0);
#                                      return $sock;});
# $mockmaster->mock('console_close',sub{return "mocked console_close";});

my $mockchild = Test::MockModule->new('Tapper::MCP::Child');
my $mocknet = Test::MockModule->new('Tapper::MCP::Net');
$mocknet->mock('tap_report_send',sub{return(0);});
$mocknet->mock('upload_files',sub{return(0);});



$mockchild->mock('install',sub{my ($self, $hostname, $fh) = @_;
                               my $pid = fork();
                               if ($pid == 0) {
                                       my $timeout = 0;
                                       sleep($timeout);
                                       my $port = $fh->sockport;
                                       print STDERR "Port in child: $port\n";
                                       my $sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp');
                                       $sock->print("start-install\n");
                                       close $sock;
                                       print STDERR "Wrote start-install\n";

                                       sleep($timeout);
                                       $sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp');
                                       $sock->print("end-install\n");
                                       close $sock;
                                       print STDERR "Wrote end-install\n";


                                       sleep($timeout);
                                       $sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp');
                                       $sock->print("prc_number:0,start-testprogram\n");
                                       close $sock;
                                       print STDERR "Wrote start-testprogram\n";


                                       sleep(600);
                                       $sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => $port, Proto => 'tcp');
                                       $sock->print("prc_number:0,end-testprogram\n");
                                       close $sock;
                                       print STDERR "Wrote end-testprogram\n";

                                       exit 0;
                               }
                               $self->cfg->{times}->{boot_timeout} = 30;
                               $self->cfg->{times}->{test_runtime_default} = 30;
                               print STDERR "Port in parent: ",$fh->sockport(),"\n";
                               return 0;});


# $mockchild->mock('runtest_handling',sub{return 0;});

my $mockschedule = Test::MockModule->new('Tapper::MCP::Scheduler');
$mockschedule->mock('get_next_testrun',sub{return('bullock',4)});

my $master   = Tapper::MCP::Master->new();
my $retval;

$master->set_interrupt_handlers();
$master->prepare_server();
#$master->cfg->{times}{poll_intervall} = 0;
foreach (1..10)
{
        my $lastrun = time();
        $master->runloop($lastrun);
}

