#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Class::C3;
use MRO::Compat;

use IO::Socket::INET;
use IO::Handle;

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Tapper::Reports::Receiver::Daemon;
use Tapper::Model 'model';
use File::Slurp 'slurp';
use Tapper::Config;
use HTTP::Daemon;

use Test::More;
use Test::Deep;

use Log::Log4perl;

my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

local $ENV{TAPPER_CONFIG_FILE} = "t/tapper.cfg";
Tapper::Config->_switch_context();

sub start_reports_receiver
{
        my ($port) = @_;

        Tapper::Reports::Receiver->new->run($port);
}

sub start_codespeed
{
        my ($PARENT_RDR, $CHILD_WTR, $CHILD_RDR, $PARENT_WTR) = @_;

        close $CHILD_RDR; close $CHILD_WTR;

        $SIG{CHLD} = 'IGNORE';
        my $d = HTTP::Daemon->new(LocalPort => 8765, ReuseAddr => 1) || die "No HTTP daemon:$!";

        # the parent waits for that message
        say $PARENT_WTR "HTTP::Daemon (fake codespeed) started.";

        my $nr = 1;
        while (my $c = $d->accept) {
                while (my $r = $c->get_request) {
                        $c->send_response("0xAFFE");
                        say $PARENT_WTR "$nr - ".$r->uri->path;
                        $nr++;
                }
                $c->close;
                undef($c);
        }
        close $PARENT_RDR; close $PARENT_WTR;
        exit 1;
}

sub send_tap_report
{
        my ($port, $taptxt) = @_;

        my $sock = IO::Socket::INET->new( PeerAddr  => 'localhost', Proto     => 'tcp',
                                          PeerPort  => $port,       ReuseAddr => 1,
                                        ) or die $!;
        is(ref($sock), 'IO::Socket::INET', "socket created - codespeed");
        my $answer = <$sock>;
        like ($answer,
              qr/^Tapper::Reports::Receiver\. Protocol is TAP\. Your report id: (\d+)/,
              "receiver api - codespeed");

        my $success = $sock->print( $taptxt );
        close $sock; # must! --> triggers the daemon's post_processing hook
}

sub check_level2_receiver
{
        my ($PARENT_RDR, $CHILD_WTR, $CHILD_RDR, $PARENT_WTR) = @_;

        my $line;
        chomp($line = <$CHILD_RDR>); is ($line, "1 - /result/add/", "request $line appeared at level2 receiver");
        chomp($line = <$CHILD_RDR>); is ($line, "2 - /result/add/", "request $line appeared at level2 receiver");
        chomp($line = <$CHILD_RDR>); is ($line, "3 - /result/add/", "request $line appeared at level2 receiver");
        chomp($line = <$CHILD_RDR>); is ($line, "4 - /result/add/", "request $line appeared at level2 receiver");
        close $CHILD_RDR; close $CHILD_WTR;
}

my $port = Tapper::Config->subconfig->{report_port};

my $pid1_receiver = fork();
if ($pid1_receiver == 0)
{
        start_reports_receiver($port);
}
else
{
        sleep 10; # wait for receiver daemon to start

        # communicate back to test program via pipe
        my ($PARENT_RDR, $CHILD_WTR, $CHILD_RDR, $PARENT_WTR);

        pipe($PARENT_RDR, $CHILD_WTR);
        pipe($CHILD_RDR, $PARENT_WTR);
        $CHILD_WTR->autoflush(1);
        $PARENT_WTR->autoflush(1);

        my $pid2_codespeed = fork;
        die "No fork: $!" unless defined $pid2_codespeed;
        if ($pid2_codespeed == 0) {
                start_codespeed($PARENT_RDR, $CHILD_WTR, $CHILD_RDR, $PARENT_WTR);
        }
        else
        {
                close $PARENT_RDR; close $PARENT_WTR;
                eval {
                        local $SIG{ALRM} = sub { die "Timeout! Starting codespeed failed!" };
                        alarm (50);
                        diag "Wait until daemon started...";
                        my $wait_for_answer = <$CHILD_RDR>;
                };
                alarm(0);
                ok (!$@, "Fake codespeed daemon started");

                eval {
                        local $SIG{ALRM} = sub { die "Timeout!" };
                        alarm (50);
                        my $taptxt = slurp("t/tap-archive-2-codespeed.tap");
                        send_tap_report($port, $taptxt);
                        check_level2_receiver ($PARENT_RDR, $CHILD_WTR, $CHILD_RDR, $PARENT_WTR);

                };
                alarm(0);
                ok (!$@, "Read and write in time - codespeed");
                kill 15, $pid1_receiver, $pid2_codespeed; sleep 3;
                kill  9, $pid1_receiver, $pid2_codespeed;
        }
}

ok(1, "finished");
done_testing();
