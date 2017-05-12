package Norma::ORM::Test::Recipe;

use Norma::ORM::Test::DB;
my $dbh = Norma::ORM::Test::DB->new->dbh;

use Moose;
use Moose::Util::TypeConstraints;

with 'Norma::ORM::Mappable' => {
	dbh => $dbh,
	table_name => 'recipes',
	relationships => [
		{ 
			name   => 'tags',
			nature => 'has_many',
			class  => 'Norma::ORM::Test::Recipe::Tag'
		}, { 
			name                => 'likes',
			nature              => 'has_many',
			class               => 'Norma::ORM::Test::Recipe::Like',
			map_table           => 'recipe_entity_likes_map',
			foreign_key         => 'entity_like_id',
			foreign_primary_key => 'recipe_id'
		}
	]
};

subtype RecipeTitle => as 'Str' => where { _validate_title($_) }    => message { "Titles must contain whitespace" };
subtype MySQLDate   => as 'Str' => where { m/\d{4}\-\d{2}\-\d{2}/ } => message { "Dates should look like YYYY-MM-DD" };

has '+title'      => (isa => 'RecipeTitle');
has '+added_date' => (isa => 'MySQLDate');

sub _validate_title {
	return 1 if $_ =~ /\s/;
}

1;

package Norma::ORM::Test::Recipe::Tag;

use Moose;

with 'Norma::ORM::Mappable' => {
	dbh => $dbh,
	table_name => 'recipe_tags'
};

package Norma::ORM::Test::Recipe::Like::Map;

use Moose;

with 'Norma::ORM::Mappable' => {
	dbh => $dbh,
	table_name => 'recipe_entity_likes_map',
};

package Norma::ORM::Test::Recipe::Like;

use Moose;

with 'Norma::ORM::Mappable' => {
	dbh => $dbh,
	table_name => 'entity_likes',
};

package Norma::ORM::Test::Recipe::Comment;

use Moose;

with 'Norma::ORM::Mappable' => {
	dbh => $dbh,
	table_name => 'recipe_comments'
}
