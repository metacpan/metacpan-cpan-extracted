use strict;

use Test::More;
use Data::Dumper;

our $db;

BEGIN {
	use Norma::ORM::Test::DB;
	$db = Norma::ORM::Test::DB->new;
	$db->initialize;
}

my $dbh = $db->dbh;

use Norma::ORM::Test::Recipe;

my $recipe = Norma::ORM::Test::Recipe->new(
	title => 'Eggs Benedict',
	ingredients => 'eggs, butter',
	instructions => 'poach eggs, etc',
	added_date => '2001-01-01',
);
$recipe->save;

$recipe->title("Poached Eggs with Hollandaise");

$recipe->save;

is( $recipe->title, "Poached Eggs with Hollandaise", "changed values stick with 'save'" );

$recipe->reload;

my $manual_title = $dbh->selectrow_array("select title from recipes where id = ?", undef, $recipe->id);

is( $manual_title, "Poached Eggs with Hollandaise", "changed values persist in database" );

$db->initialize;

my $scrambled_recipe = Norma::ORM::Test::Recipe->new(
	title => 'Scrambled Eggs',
	ingredients => 'eggs',
	instructions => 'scramble eggs',
	added_date => '2010-01-02',
);
$scrambled_recipe->save;

my $poached_recipe = Norma::ORM::Test::Recipe->new(
	title => 'Poached Eggs',
	ingredients => 'eggs',
	instructions => 'poach eggs',
	added_date => '2010-01-02',
);
$poached_recipe->save;

$poached_recipe->added_date('1900-01-01');

$scrambled_recipe->reload;
$poached_recipe->reload;

is( $scrambled_recipe->added_date, '2010-01-02', 'initial row unchanged' );
is( $poached_recipe->added_date, '2010-01-02', 'second row updated correctly' );

done_testing;

