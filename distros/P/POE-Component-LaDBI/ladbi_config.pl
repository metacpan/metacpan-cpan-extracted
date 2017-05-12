
use IO::File;
use File::Spec;

our $BASE_CFG_FN = "config.pcf";
our @CFG_PARAMS  = qw(DSN USER PASSWD);
our $NO_DB_TESTS_FN = "NO_DB_TESTS";
our $TEST_LOG_FN = "test.log";

our ($TEST_TABLE) = 'ladbi_test';
our (@TABLE_DATA) = (
		     [qw( jim  becket 111-555-1111 jbecket@company.com )],
		     [qw( john dunne  222-555-2222 jdunne@company.com  )],
		     [qw( jane wilks  333-555-3333 jwilks@company.com  )]
		    );

our @EXTRA_ROW = qw( bob smith 444-555-4444 bsmith@company.com );

our $LADBI_ALIAS = 'ladbi';

our $CREATE_TABLE_SQL = <<"EOSQL";
CREATE TABLE $TEST_TABLE
  (
    firstname VARCHAR(32) NOT NULL,
    lastname  VARCHAR(32) NOT NULL,
    phone     VARCHAR(32) NOT NULL,
    email     VARCHAR(32) NOT NULL
  )
EOSQL

sub find_file_up {
  my ($f,$n) = @_;
  return $f if -r $f;
  my $up = File::Spec->updir();
  return unless $up;
  for (1..$n) {
    $f = File::Spec->catfile($up, $f);
    return unless $f;
    return $f if -r $f;
  }
  return;
}

sub load_cfg_file {
  my ($f) = @_;
  my ($cfg);
  eval { $cfg = do $f; };
  if ($@) {
    warn $@;
    return;
  }
  return $cfg;
}

sub stop_all_tests {
  print "Bail out!\n", @_;
}


