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

package Norma::ORM::Test::Recipe;

use Moose;

with 'Norma::ORM::Mappable' => {

	table_name => 'recipes',
	dbh => $dbh,
};

has 'non_savable_attribute' => (is => 'rw');

1;

package main;

my $recipe = Norma::ORM::Test::Recipe->new(
	title => 'Eggs Benedict',
	ingredients => 'eggs, butter',
	instructions => 'poach eggs, etc',
	added_date => '2001-01-01',
);

$recipe->non_savable_attribute(42);
$recipe->save;

my $recipe_id = $recipe->id;

$recipe = Norma::ORM::Test::Recipe->load( id => $recipe_id );

is($recipe->non_savable_attribute, undef, "non-savable attributes don't inhibit saving altogether");

$recipe->ingredients('eggs, butter, salt');
$recipe->save;

my $ingredients = $dbh->selectrow_array("select ingredients from recipes where id = ?", undef, $recipe_id);

is($ingredients, 'eggs, butter, salt', "non-savable attributes don't inhibit updates");

done_testing;

