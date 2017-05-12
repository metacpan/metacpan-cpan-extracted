use strict;
no warnings;

use Test::More;

use Norma::DB;
use Norma::ORM::Test::DB;

if ( $ENV{NORMA_UNIT_TEST_DB_DRIVER} eq 'mysql' ) {

	my $db = Norma::DB->initialize(
		username => 'tester',
		password => 'tester',
		dsn => 'dbi:mysql:database=unit_testing',
	);

	ok( $db->dbh->isa("DBI::db"), 'manual mysql dsn gets us a DBI::db' );

	my $dbh = $db->dbh;

	$db = Norma::DB->initialize( dbh => $dbh );
	ok( $db->dbh->isa("DBI::db"), 'pre-made handle makes it through' );

} else {

	my $dsn = "dbi:SQLite:dbname=/tmp/norma-unit-testing-$$";

	my $db = Norma::DB->initialize( dsn => $dsn );
	ok( $db->dbh->isa("DBI::db"), 'manual sqlite dsn gets us a DBI::db' );
}

my $unit_test_db = Norma::ORM::Test::DB->new;
$unit_test_db->initialize;

my $db = Norma::DB->initialize( dbh => $unit_test_db->dbh );

my $id = $db->insert(
	table_name => 'recipes',
	values => {
		ingredients => 'eggs, tomatoes',
		title => 'breakfast',
		added_date => '2010-01-01',
	}
);

is($id, 1, 'got primary id from insert');

my $selection = $db->select(
	table_name => 'recipes',
	where => "where id = $id", 
	join => 'recipes',
); 

is_deeply(
	$selection,
	{
		total_count => 1,
		query => 'select recipes.* from recipes where id = 1',
		rows => [
			{
				id => 1,
				ingredients => 'eggs, tomatoes',
				title => 'breakfast',
				added_date => '2010-01-01',
				contributor_person_id => undef,
				instructions => undef,
				category_id => undef,
				description => undef,
				contributor_name => undef,
			}
		],
	},
	"we got back what we put in"
);

$db->update(
	table_name => 'recipes',
	values => { added_date => sub { "DATE('2010-12-31')" } }
);

my $updated_date = $db->dbh->selectrow_array("select added_date from recipes");

is( $updated_date, '2010-12-31', 'subref values are passed through okay' );

done_testing;

