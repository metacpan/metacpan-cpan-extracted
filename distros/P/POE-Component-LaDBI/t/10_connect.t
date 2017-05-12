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

$LOG->print("### connect.t\n");

use Data::Dumper;

my $OK = 0;

POE::Component::LaDBI->create(Alias => $LADBI_ALIAS)
  or stop_all_tests("Failed: POE::Component::LaDBI->create()\n");

POE::Session->create
  (
   inline_states =>
   {
    _start     => sub {
      my $args = [$CFG->{DSN}, $CFG->{USER}, $CFG->{PASSWD}];
      $LOG->print("_start: >", join(',',@$args), "<\n");
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'connect'     ,
			SuccessEvent => 'disconnect',
			FailureEvent => 'dberror'     ,
			Args         => [$CFG->{DSN}, $CFG->{USER}, $CFG->{PASSWD}],
			UserData     => $_[HEAP]->{user_data}
		      );
    },
    _stop     => sub { $LOG->print("_stop: test session died\n"); },
    shutdown   => sub {
      $LOG->print("shutdown\n");
      $_[KERNEL]->post($LADBI_ALIAS => 'shutdown');
    },
    disconnect => sub {
      my ($dbh_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      if ($_[HEAP]->{user_data} ne $user_data) {
	$OK = 0;
	$LOG->print("failed user_data match; state=$_[STATE];\n");
	$_[KERNEL]->yield('shutdown');
	return;
      }
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'disconnect',
			SuccessEvent => 'disconnected',
			FailureEvent => 'dberror'   ,
			HandleId     => $dbh_id     ,
			UserData     => $_[HEAP]->{user_data}
		      );
    },
    disconnected => sub {
      my ($sth_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      $LOG->print("disconnected\n");
      if ($_[HEAP]->{user_data} ne $user_data) {
	$OK = 0;
	$LOG->print("failed user_data match; state=$_[STATE];\n");
	$_[KERNEL]->yield('shutdown');
	return;
      }
      $OK = 1;
      $_[KERNEL]->yield('shutdown');
    },
    dberror    => sub {
      my ($handle_id, $errtype, $errstr, $err, $user_data) = @_[ARG0..ARG4];
      $LOG->print("dberror: handler id = $handle_id\n");
      $LOG->print("dberror: errtype    = $errtype  \n");
      $LOG->print("dberror: errstr     = $errstr   \n");
      if ($_[HEAP]->{user_data} ne $user_data) {
	$OK = 0;
	$LOG->print("failed user_data match; state=$_[STATE];\n");
	$_[KERNEL]->yield('shutdown');
	return;
      }
      $LOG->print("dberror: err        = $err      \n") if $errtype eq 'ERROR';
      $_[KERNEL]->yield('shutdown');
    },
   }
  )
  or stop_all_tests("Failed to create test POE::Session\n");

$poe_kernel->run();

$LOG->close();

ok($OK);
