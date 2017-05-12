use strict;

use Test::More;
use Data::Dumper;

BEGIN {
	my $db;
	use Norma::ORM::Test::DB;
	$db = Norma::ORM::Test::DB->new;
	$db->initialize;
}

use Norma::DB;
use Norma::ORM::Test::DB;

my $unit_test_db = Norma::ORM::Test::DB->new;
$unit_test_db->initialize;

my $db = Norma::DB->initialize( dbh => $unit_test_db->dbh );

$db->dbh->do("drop table if exists people");
$db->dbh->do( qq{
	create table people (
		id int primary key, 
		name varchar(255), 
		social_security_number int, 
		unique(social_security_number), 
		unique(social_security_number, name)
	)
} );


my $fields = $db->get_table_primary_key_field_names( table_name => 'people' );
is_deeply($fields, ['id'], 'primary keys look okay');

$fields = $db->get_table_key_field_names( table_name => 'people' );
is_deeply([ sort @$fields ], [ sort qw(id social_security_number) ], 'unique indexes look alright');

done_testing;

