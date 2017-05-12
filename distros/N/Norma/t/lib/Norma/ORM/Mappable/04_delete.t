use strict;

use Test::More;
use Test::Exception;
use Data::Dumper;

our $db;

BEGIN {
	use Norma::ORM::Test::DB;
	$db = Norma::ORM::Test::DB->new;
	$db->initialize;
}

my $dbh = $db->dbh;

# create a new recipe

use Norma::ORM::Test::Recipe;

my $recipe = Norma::ORM::Test::Recipe->new(
	title => 'Eggs Benedict',
	ingredients => 'eggs, butter',
	instructions => 'poach eggs, etc',
	added_date => '2001-01-01',
);
$recipe->save;

$recipe->delete;

my $count = $dbh->selectrow_array("select count(*) from recipes");
is ($count, 0, 'no rows left after deleting');

throws_ok( sub { $recipe->reload }, qr/no row by that criteria/, "we die trying to reload a deleted object" );

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

$scrambled_recipe->delete;

my $recipe_titles = $dbh->selectcol_arrayref("select title from recipes");

is (scalar @$recipe_titles, 1, "one recipe left after deleting one of two");

is (shift @$recipe_titles, "Poached Eggs", "the recipe left is the one we didn't delete");

done_testing;

