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

# add some tags

my $tag_ids = {};

for my $tag (qw(brunch difficult fatty fancy)) {

	my $tag = Norma::ORM::Test::Recipe::Tag->new( word => $tag, recipe_id => $recipe->id );
	$tag->save;

	$tag_ids->{ $tag->word } = $tag->id;
}

my $tags_count = $dbh->selectrow_array("select count(*) from recipe_tags");
is( $tags_count, 4, "'merge' inserts new items" );

my $brunch = Norma::ORM::Test::Recipe::Tag->new( word => 'brunch', recipe_id => $recipe->id );
$brunch->merge;
is( $brunch->id, $tag_ids->{brunch}, "'merge' retrieves existing ids correctly" );

$tags_count = $dbh->selectrow_array("select count(*) from recipe_tags");
is( $tags_count, 4, "'merge' doesn't insert duplicate rows" );

# unload the recipe and load it up again

my $recipe_id = $recipe->id;
undef $recipe;

$recipe = Norma::ORM::Test::Recipe->load(id => $recipe_id);

is($recipe->{tags}, undef, "lazy relational data is missing to start");

is_deeply(
	[sort map { $_->{word} } $recipe->tags->items], 
	[sort qw(brunch difficult fatty fancy)], 
	'has_many relational data looks alright'
);

isnt($recipe->{tags}, undef, "lazy relational data is populated after reading");

done_testing;

