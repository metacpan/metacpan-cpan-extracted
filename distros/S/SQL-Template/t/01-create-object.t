use strict;
use Test::More tests => 28;


use_ok( 'SQL::Template' );	
use_ok( 'DBI' );
use_ok( 'DBD::SQLite' ) or die "DBD::SQLite is required for testing";


my $dbh = DBI->connect("dbi:SQLite:dbname=./t/db/sqltemplate.sqlite","","", {AutoCommit=>0});

ok( defined($dbh), "DB Connection established");

$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;


my $sql = SQL::Template->new(-filename=>"./t/conf/01-test.xml");
ok( $sql->isa('SQL::Template'), "SQL::Template object created");


ok( $sql->do("drop_table_person", $dbh), "Drop table person");
ok( $sql->do("drop_table_country", $dbh), "Drop table country");

ok( $sql->do("create_table_country", $dbh), "Create table country");
ok( $sql->do("create_table_person", $dbh), "Create table person");


my $countries = [
	{COUNTRY_ID=>'ES', NAME=>'SPAIN'},
	{COUNTRY_ID=>'UK', NAME=>'UNITED KINGDOM'},
];
foreach my $country(@$countries) {
	ok( 1 == $sql->do("insert_country", $dbh, $country), "New country added: $country->{NAME}");
}

my $persons = [
{ID=>1, NAME=>'MIGUEL', SURNAME=>'CERVANTES', BORNDATE=>'29/09/1547', COUNTRY_ID=>'ES', GENDER=>'M'},
{ID=>2, NAME=>'WILLIAN', SURNAME=>'SHAKESPEARE', BORNDATE=>'26/04/1554', COUNTRY_ID=>'UK', GENDER=>'M'},
{ID=>3, NAME=>'JOSE MARIA', SURNAME=>'PEREDA', BORNDATE=>'19/03/1833', COUNTRY_ID=>'ES', GENDER=>'M'},
{ID=>4, NAME=>'GUSTAVO ADOLFO', SURNAME=>'BECQUER', BORNDATE=>'17/02/1836', COUNTRY_ID=>'ES', GENDER=>'M'},
{ID=>5, NAME=>'ROSALIA', SURNAME=>'DE CASTRO', BORNDATE=>'24/02/1837', COUNTRY_ID=>'ES', GENDER=>'F'},
{ID=>6, NAME=>'JUAN RAMON', SURNAME=>'JIMENEZ', BORNDATE=>'23/12/1881', COUNTRY_ID=>'ES', GENDER=>'M'},
{ID=>7, NAME=>'RAFAEL', SURNAME=>'ALBERTI', BORNDATE=>'16/12/1902', COUNTRY_ID=>'ES', GENDER=>'M'},
];

foreach my $person(@$persons) {
	ok( 1 == $sql->do("insert_person", $dbh, $person), "New person added: $person->{SURNAME}");
}


my $stmt = $sql->select_stmt("query_for_person", $dbh );
while( my $hr = $stmt->fetchrow_hashref ) {
	ok( $hr->{NAME} eq $persons->[$hr->{ID}-1]->{NAME}, "found [$hr->{ID}] $hr->{NAME} record");
}
$stmt->finish;

$stmt = $sql->select_stmt("query_for_person", $dbh, {ID=>2} );
if( my $hr = $stmt->fetchrow_hashref ) {
	ok( $hr->{NAME} eq $persons->[1]->{NAME}, "Record found: $hr->{NAME}, expected: $persons->[1]->{NAME}");
}
else {
	diag("No record found");
}
$stmt->finish;


my ($count) = $sql->selectrow_array("count_people", $dbh, {ID=>2} );
ok( $count == 1, "Record count 1 with ID=2");

my ($count_all) = $sql->selectrow_array("count_people", $dbh );
ok( $count_all == 7, "Table record count 7");

$dbh->commit;
$dbh->disconnect;

