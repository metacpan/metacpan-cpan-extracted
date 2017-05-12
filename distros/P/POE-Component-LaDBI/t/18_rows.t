use strict;
use warnings;

use Test;
BEGIN { plan test => 1 };

use IO::File;
use IO::Handle;
use Symbol ();

use POE;
use POE::Component::LaDBI;

use vars qw($NO_DB_TESTS_FN $BASE_CFG_FN $LADBI_ALIAS $TEST_LOG_FN $TEST_TABLE @TABLE_DATA);
require "ladbi_config.pl";

if (find_file_up($NO_DB_TESTS_FN, 1)) {
  skip("skip no database tests", 1);
  exit 0;
}

my $CFG = load_cfg_file( find_file_up($BASE_CFG_FN,0) );


my $LOG = IO::File->new($TEST_LOG_FN, "a") or exit 1;
$LOG->autoflush(1);

$LOG->print("### rows.t\n");

use Data::Dumper;

#my $SQL = "SELECT phone FROM $TEST_TABLE WHERE firstname = ?";
my $SQL = "UPDATE $TEST_TABLE SET phone = ? WHERE firstname = ?";
my $PHONE = '111-555-1111';
my $FNAME = 'jim';
my $ROWS = 1;

my $OK = 0;

POE::Component::LaDBI->create(Alias => $LADBI_ALIAS)
  or stop_all_tests("Failed: POE::Component::LaDBI->create()\n");

POE::Session->create
  (
   inline_states =>
   {
    _start      => sub {
      my $args = [$CFG->{DSN}, $CFG->{USER}, $CFG->{PASSWD}];
      $LOG->print("_start: >", join(',',@$args), "<\n");
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'connect',
			SuccessEvent => 'prepare',
			FailureEvent => 'dberror',
			Args => [$CFG->{DSN}, $CFG->{USER}, $CFG->{PASSWD}],
                        UserData     => $_[HEAP]->{user_data}
		      );
    },
    _stop       => sub { $LOG->print("_stop: test session died\n"); },
    shutdown    => sub {
      $LOG->print("shutdown\n");
      $_[KERNEL]->post($LADBI_ALIAS => 'shutdown');
    },
    prepare     => sub {
      my ($dbh_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      $LOG->print("prepare: $SQL\n");
      $_[HEAP]->{dbh_id} = $dbh_id;
      if ($_[HEAP]->{user_data} ne $user_data) {
        $OK = 0;
        $LOG->print("failed user_data match; state=$_[STATE];\n");
        $_[KERNEL]->yield('shutdown');
        return;
      }
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'prepare',
			SuccessEvent => 'execute',
			FailureEvent => 'dberror',
			HandleId     => $dbh_id,
			Args => [ $SQL ],
                        UserData     => $_[HEAP]->{user_data}
		      );
    },
    execute    => sub {
      my ($sth_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      $LOG->print("execute: sth_id=$sth_id\n");
      if ($_[HEAP]->{user_data} ne $user_data) {
        $OK = 0;
        $LOG->print("failed user_data match; state=$_[STATE];\n");
        $_[KERNEL]->yield('shutdown');
        return;
      }
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'execute',
			SuccessEvent => 'rows',
			FailureEvent => 'dberror',
			HandleId     => $sth_id,
			Args => [ $PHONE, $FNAME ],
                        UserData     => $_[HEAP]->{user_data}
		     );
    },
    rows       => sub {
      my ($sth_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      $LOG->print("fetch: sth_id=$sth_id\n");
      if ($_[HEAP]->{user_data} ne $user_data) {
        $OK = 0;
        $LOG->print("failed user_data match; state=$_[STATE];\n");
        $_[KERNEL]->yield('shutdown');
        return;
      }
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'rows',
			SuccessEvent => 'cmp_results',
			FailureEvent => 'dberror',
			HandleId     => $sth_id,
                        UserData     => $_[HEAP]->{user_data}
		      );
    },
    cmp_results => sub {
      my ($sth_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      my $ok = 0;
      my $err = 'success';
      if ($_[HEAP]->{user_data} ne $user_data) {
        $OK = 0;
        $LOG->print("failed user_data match; state=$_[STATE];\n");
        $_[KERNEL]->yield('shutdown');
        return;
      }
      unless ($datatype = 'RV') {
	$err = "datatype != 'RV', datatype=$datatype";
	goto CMP_YIELD;
      }
      unless (defined $data) {
	$err = "data undefined";
	goto CMP_YIELD;
      }
      unless ($ROWS eq $data) {
	$err = "not the correct result; expected $ROWS; found $data;";
	goto CMP_YIELD;
      }
      $ok = 1;
    CMP_YIELD:
      $OK = $ok;
      $LOG->print("cmp_results: $err\n");
      $_[KERNEL]->yield('finish', $sth_id);
    },
    finish     => sub {
      $LOG->print("$_[STATE]:\n");
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'finish',
			SuccessEvent => 'disconnect',
			FailureEvent => 'dberror',
			HandleId => $_[ARG0],
                        UserData     => $_[HEAP]->{user_data}
		      );
    },
    disconnect => sub {
      my ($sth_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      my $dbh_id = $_[HEAP]->{dbh_id};
      $LOG->print("disconnect: dbh_id=$dbh_id\n");
      if ($_[HEAP]->{user_data} ne $user_data) {
        $OK = 0;
        $LOG->print("failed user_data match; state=$_[STATE];\n");
        $_[KERNEL]->yield('shutdown');
        return;
      }
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'disconnect',
			SuccessEvent => 'shutdown'  ,
			FailureEvent => 'dberror'   ,
			HandleId     => $dbh_id,
                        UserData     => $_[HEAP]->{user_data}
		      );
    },
    dberror    => sub {
      my ($handle_id, $errtype, $errstr, $err, $user_data) = @_[ARG0..ARG4];
      $OK = 0;
      $LOG->print("dberror: handler id = $handle_id\n");
      $LOG->print("dberror: errtype    = $errtype  \n");
      $LOG->print("dberror: errstr     = $errstr   \n");
      $LOG->print("dberror: err        = $err      \n") if $errtype eq 'ERROR';
      if ($_[HEAP]->{user_data} ne $user_data) {
        $OK = 0;
        $LOG->print("failed user_data match; state=$_[STATE];\n");
        $_[KERNEL]->yield('shutdown');
        return;
      }
      $_[KERNEL]->yield('shutdown');
    },
   }
  )
  or stop_all_tests("Failed to create test POE::Session\n");

$poe_kernel->run();

$LOG->close();

ok($OK);
