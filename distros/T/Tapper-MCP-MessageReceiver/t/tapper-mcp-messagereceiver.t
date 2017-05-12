#!perl

use warnings;
use strict;

use Tapper::Config;

use IO::Socket::INET;
use Test::More;
use YAML::Syck;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;

use Tapper::MCP::MessageReceiver;
use English "-no_match_vars";

use File::Temp qw/  tempdir /;

construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_empty.yml' );

my $dir = tempdir( CLEANUP => 1 );
$ENV{TAPPER_MSG_RECEIVER_PIDFILE} = "$dir/pid";

my $pid = fork;

BAIL_OUT("fork failed") if not defined $pid;

if ($pid == 0) {
        exec qq($EXECUTABLE_NAME -Ilib bin/tapper-mcp-messagereceiver 2>&1);
} else {
        {
                no warnings;
                # give server time to settle
                sleep ($ENV{TAPPER_SLEEPTIME} || 10);
        }

        ok(kill(0, $pid), 'Daemon started');

        # eval makes sure the server is stopped at the end. Please leave it intakt
        eval {
                my $sender = IO::Socket::INET->new(PeerAddr => 'localhost',
                                                   PeerPort => Tapper::Config::subconfig->{mcp_port},
                                                  );
                ok(($sender and $sender->connected), 'Connected to server');
                $sender->say("GET /state/start_install/testrun_id/4/ HTTP/1.0\r\n\r\n");
                $sender->close();
                {
                        no warnings;
                        # give server time to do his work
                        sleep( $ENV{TAPPER_SLEEPTIME} || 10);
                }
                my $messages = model('TestrunDB')->resultset('Message')->search({testrun_id => 4});
                is($messages->count, 1, 'One message for testrun 4 in DB');
                is_deeply($messages->first->message, {testrun_id => 4, state => 'start_install'}, 'Expected message in DB');
                is($messages->first->type, , 'state', 'Expected status in DB');

        };
        fail($@) if $@;

        # eval makes sure the server is stopped at the end. Please leave it intakt
        eval {
                my $sender = IO::Socket::INET->new(PeerAddr => 'localhost',
                                                   PeerPort => Tapper::Config::subconfig->{mcp_port},
                                                  );
                ok(($sender and $sender->connected), 'Connected to server');
                $sender->say("GET /action/reset/host/bullock HTTP/1.0\r\n\r\n");
                $sender->close();
                {
                        no warnings;
                        # give server time to do his work
                        sleep( $ENV{TAPPER_SLEEPTIME} || 10);
                }
                my $messages = model('TestrunDB')->resultset('Message')->search({type => 'action'});
                is($messages->count, 1, 'One message for type action in DB');
                is_deeply($messages->first->message, {action => 'reset', host => 'bullock'}, 'Expected message in DB');
                is($messages->first->type, , 'action', 'Expected status in DB');

        };
        fail($@) if $@;

        ok(kill(9, $pid), 'Daemon stopped');
        done_testing;
}
