use strict;
use warnings;

use Test;
BEGIN { plan test => 1 };

use IO::File;
use IO::Handle;
use Symbol ();

use POE;
use POE::Component::LaDBI;

use vars qw($NO_DB_TESTS_FN $BASE_CFG_FN $LADBI_ALIAS $TEST_LOG_FN);
require "ladbi_config.pl";

if (find_file_up($NO_DB_TESTS_FN, 1)) {
  skip("skip no database tests", 1);
  exit 0;
}

my $CFG = load_cfg_file( find_file_up($BASE_CFG_FN,0) );


my $LOG = IO::File->new($TEST_LOG_FN, "a") or exit 1;
$LOG->autoflush(1);

$LOG->print("### offline.t\n");

use Data::Dumper;

my $OK = 0;

POE::Component::LaDBI->create(Alias => $LADBI_ALIAS)
  or stop_all_tests("Failed: POE::Component::LaDBI->create()\n");

POE::Session->create
  (
   inline_states =>
   {
    _start     => sub {
      $LOG->print("_start: \n");
      $_[KERNEL]->alias_set("test");
      $_[KERNEL]->call($LADBI_ALIAS => "register",
		       OfflineEvent => "db_offline");
      $_[KERNEL]->post($LADBI_ALIAS => "shutdown", "test", "test");
      $_[KERNEL]->delay_set("timeout", 10);
    },
    _stop     => sub { $LOG->print("_stop: test session died\n"); },
    shutdown     => sub {
      $LOG->print("shutdown\n");
      $_[KERNEL]->alias_remove("test");
    },
    db_offline   => sub {
      $LOG->print("db_offline: cause=", $_[ARG0], "; errstr=", $_[ARG1],
		  "; alias=", $_[ARG2], ";\n");
      $OK = 1;
      $_[KERNEL]->alarm_remove_all();
      $_[KERNEL]->yield('shutdown');
    },
    timeout => sub {
      $LOG->print("timeout\n");
      $OK = 0;
    }
   }
  )
  or stop_all_tests("Failed to create test POE::Session\n");

$poe_kernel->run();

$LOG->close();

ok($OK);
