use DBI;

use Test;
BEGIN { plan test => 1 };

use vars qw($NO_DB_TESTS_FN $BASE_CFG_FN @CFG_PARAMS
	    $TEST_TABLE @TABLE_DATA $CREATE_TABLE_SQL);
require "ladbi_config.pl";

if (find_file_up($NO_DB_TESTS_FN, 1)) {
  skip("skip no database tests", 1);
  exit 0;
}

my $cfg = load_cfg_file( find_file_up($BASE_CFG_FN,0) );

my $ok = 1;

my $dbh = DBI->connect($cfg->{DSN}, $cfg->{USER}, $cfg->{PASSWD},
		       {RaiseError => 0, AutoCommit => 1});

unless (defined $dbh) {
  print "Bail out!\n", "#Failed to connect to database\n";
  exit 0;
}

my ($rv);

$rv = $dbh->do($CREATE_TABLE_SQL);

unless (defined $rv) {
  print "Bail out!\n", "#Failed to create table, $TEST_TABLE\n";
  exit 0;
}


for my $row (@TABLE_DATA) {
  my (@qrow) = map { $dbh->quote($_) } @$row;
  my ($firstname, $lastname, $phone, $email) = @qrow;
  
  $rv = $dbh->do(<<"EOSQL");
INSERT INTO $TEST_TABLE ( firstname, lastname, phone, email )
       VALUES      ( $firstname, $lastname, $phone, $email )
EOSQL

  unless (defined $rv) {
    print "Bail out!\n", "#Failed to drop table, $TEST_TABLE\n";
    $ok = 0;

    # vain attempt to clean up
    $rv = $dbh->do(<<"EOSQL");
DROP TABLE $TEST_TABLE ;
EOSQL
  }
}

#$dbh->commit(); #unnessesary now that AutoCommit is on

$dbh->disconnect();

ok($ok);
