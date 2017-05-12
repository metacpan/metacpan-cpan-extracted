use strict;
use warnings;

use Test;
BEGIN { plan test => 1 };

use IO::File;
use IO::Handle;
use Symbol ();

use POE;
use POE::Component::LaDBI;

use Data::Dumper;

use vars qw($NO_DB_TESTS_FN $BASE_CFG_FN $LADBI_ALIAS $TEST_LOG_FN $TEST_TABLE @EXTRA_ROW);
require "ladbi_config.pl";

if (find_file_up($NO_DB_TESTS_FN, 1)) {
  skip("skip no database tests", 1);
  exit 0;
}

my $CFG = load_cfg_file( find_file_up($BASE_CFG_FN,0) );


my $LOG = IO::File->new($TEST_LOG_FN, "a") or exit 1;
$LOG->autoflush(1);

$LOG->print("### rollback.t\n");

use Data::Dumper;

my $DO_SQL = <<"EOSQL";
DELETE FROM $TEST_TABLE WHERE firstname = ? AND lastname = ?
EOSQL

my $DO_ATTR = { AutoCommit => 0 };
my (@DO_VALUES) = @EXTRA_ROW[0,1];

my $SELECT_SQL = "SELECT * FROM $TEST_TABLE WHERE firstname = ? AND lastname = ?";

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
			SuccessEvent => 'do_sql',
			FailureEvent => 'dberror',
			Args => [$CFG->{DSN}, $CFG->{USER}, $CFG->{PASSWD},
				 { AutoCommit => 0 } ],
                        UserData     => $_[HEAP]->{user_data}
		      );
    },
    _stop       => sub { $LOG->print("_stop: test session died\n"); },
    shutdown    => sub {
      $LOG->print("shutdown\n");
      $_[KERNEL]->post($LADBI_ALIAS => 'shutdown');
    },
    do_sql   => sub {
      my ($dbh_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      $_[HEAP]->{dbh_id} = $dbh_id;
      $LOG->print("do_sql: dbh_id=$dbh_id\n");
      if ($_[HEAP]->{user_data} ne $user_data) {
        $OK = 0;
        $LOG->print("failed user_data match; state=$_[STATE];\n");
        $_[KERNEL]->yield('shutdown');
        return;
      }
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'do',
			SuccessEvent => 'first_cmp_results',
			FailureEvent => 'dberror',
			HandleId     => $dbh_id,
			Args         => [ $DO_SQL, $DO_ATTR, @DO_VALUES ],
                        UserData     => $_[HEAP]->{user_data}
		      );
    },
    first_cmp_results => sub {
      my ($dbh_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      $LOG->print("first_cmp_results: dbh_id=$dbh_id\n");
      my $err = 'success';
      if ($_[HEAP]->{user_data} ne $user_data) {
        $OK = 0;
        $LOG->print("failed user_data match; state=$_[STATE];\n");
        $_[KERNEL]->yield('shutdown');
        return;
      }
      unless ($datatype eq 'RV') {
	$err = "datatype != 'RV', datatype=$datatype";
	goto CMP_YIELD_ONE;
      }
      unless (defined $data) {
	$err = 'data undefined';
	goto CMP_YIELD_ONE;
      }
      $LOG->print(Dumper($data));
      unless ($data == 1) {
	$err = "data != 1, data == $data";
	goto CMP_YIELD_ONE;
      }
    CMP_YIELD_ONE:
      $LOG->print("first_cmp_results: $err\n");
      $_[KERNEL]->yield('rollback');
    },
    rollback => sub {
      my ($dbh_id) = $_[HEAP]->{dbh_id};
      $LOG->print("rollback: dbh_id=$dbh_id\n");
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'rollback',
			SuccessEvent => 'confirm_rollback',
			FailureEvent => 'dberror'   ,
			HandleId     => $dbh_id,
                        UserData     => $_[HEAP]->{user_data}
		      );
    },
    confirm_rollback => sub {
      my ($dbh_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      $LOG->print("confirm_rollback: dbh_id=$dbh_id\n");
      if ($_[HEAP]->{user_data} ne $user_data) {
        $OK = 0;
        $LOG->print("failed user_data match; state=$_[STATE];\n");
        $_[KERNEL]->yield('shutdown');
        return;
      }
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'selectall',
			SuccessEvent => 'second_cmp_results',
			FailureEvent => 'dberror'   ,
			HandleId     => $dbh_id,
			Args => [ $SELECT_SQL, $DO_ATTR, @DO_VALUES ],
                        UserData     => $_[HEAP]->{user_data}
		      );
    },
    second_cmp_results => sub {
      my ($dbh_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      $LOG->print("second_cmp_results: dbh_id=$dbh_id\n");
      my $err = 'success';
      my $ok = 0;
      if ($_[HEAP]->{user_data} ne $user_data) {
        $OK = 0;
        $LOG->print("failed user_data match; state=$_[STATE];\n");
        $_[KERNEL]->yield('shutdown');
        return;
      }
      unless ($datatype eq 'TABLE') {
	$err = "datatype != 'TABLE', datatype=$datatype";
	goto CMP_YIELD_TWO;
      }
      unless (defined $data) {
	$err = 'data undefined';
	goto CMP_YIELD_TWO;
      }
      $LOG->print(Dumper($data));
      unless (@$data == 1) {
	$err = "nrows != 1; nrows == ".scalar(@$data);
	goto CMP_YIELD_TWO;
      }
      $ok = 1;
    CMP_YIELD_TWO:
      $OK = $ok;
      $LOG->print("second_cmp_results: $err\n");
      $_[KERNEL]->yield('disconnect');
    },
    disconnect => sub {
      my ($dbh_id) = $_[HEAP]->{dbh_id};
      $LOG->print("disconnect: dbh_id=$dbh_id\n");
      $_[HEAP]->{user_data} = Symbol::gensym();
      $_[KERNEL]->post( $LADBI_ALIAS => 'disconnect',
			SuccessEvent => 'disconnected',
			FailureEvent => 'dberror'   ,
			HandleId     => $dbh_id,
                        UserData     => $_[HEAP]->{user_data}
		      );
    },
    disconnected => sub {
      my ($dbh_id, $datatype, $data, $user_data) = @_[ARG0..ARG3];
      $LOG->print("$_[STATE]:\n");
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
