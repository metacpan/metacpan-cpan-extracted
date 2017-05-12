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

$recipe = Norma::ORM::Test::Recipe->new(
	title => 'Western Omlette',
	ingredients => 'eggs, ham, green pepper, onion, tomato',
	instructions => 'cook, omlette style',
	added_date => '2001-01-01',
);
$recipe->save;

my $recipes = Norma::ORM::Test::Recipe->collect;

is($recipes->total_count, 2, "two recipes made it in");

my $recipe_comment = Norma::ORM::Test::Recipe::Comment->new(
	recipe_id => $recipe->id,
	text => 'alright'
);
$recipe_comment->save;

$recipes = Norma::ORM::Test::Recipe->collect(
	join => [ recipe_comments => 'recipes.id = recipe_comments.recipe_id' ]
);

is($recipes->total_count, 1, "we get one recipe back");
is($recipes->items->[0]->id, $recipe->id, "we get the recipe with the comment");

done_testing;

1;
