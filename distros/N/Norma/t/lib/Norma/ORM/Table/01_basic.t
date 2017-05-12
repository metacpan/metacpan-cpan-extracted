use strict;
use Test::More;
use Data::Dumper;

use Norma::ORM::Test::DB;
my $test_db = Norma::ORM::Test::DB->new;

$test_db->initialize;
my $dbh = $test_db->dbh;

use Norma::DB;
my $norma_db = Norma::DB->initialize(dbh => $dbh);

use Norma::ORM::Table;
my $table = Norma::ORM::Table->new(
	name => 'recipes',
	db => $norma_db
);

my @discovered_columns = sort map { $_->{COLUMN_NAME} } @{ $table->columns };

print Dumper $table;

my @expected_columns = sort qw(
	id 
	contributor_person_id 
	added_date 
	title 
	description 
	ingredients 
	instructions 
	contributor_name 
	category_id
); 

is_deeply( \@discovered_columns, \@expected_columns, 'column names look right' );

done_testing;


