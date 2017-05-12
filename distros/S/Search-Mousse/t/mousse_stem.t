#!perl
use strict;
use File::Path;
use List::Uniq qw(uniq);
use MealMaster;
use Test::More tests => 18;
use Text::Soundex;
use_ok("Search::Mousse");
use_ok("Search::Mousse::Writer");
use_ok("Search::Mousse::Writer::Related");

my $directory = "t/tmp";
rmtree($directory);
mkdir($directory) || die $!;

my $mousse = Search::Mousse::Writer->new(
  directory => $directory,
  name      => 'recipes',
  stemmer   => \&stemmer,
);

my $mm = MealMaster->new;
my @recipes = $mm->parse("t/0222-1.TXT");
foreach my $recipe (@recipes) {
  my $title = ucfirst(lc($recipe->title));
  $recipe->title($title);
  my $categories = join ' ', @{ $recipe->categories };
  my $words = lc "$title $categories";
  $mousse->add($recipe->title, $recipe, $words);
}
$mousse->write;

$mousse = Search::Mousse->new(
  directory => $directory,
  name      => 'recipes',
  stemmer   => \&stemmer,
);

my $related = Search::Mousse::Writer::Related->new(mousse => $mousse);
$related->write;

$mousse = Search::Mousse->new(
  directory => $directory,
  name      => 'recipes',
  stemmer   => \&stemmer,
  and       => 1,
);

my $recipe = $mousse->fetch("Hearty Russian Beet Soup");
ok(!$recipe);

$recipe = $mousse->fetch("Hearty russian beet soup");
is($recipe->title, "Hearty russian beet soup");

my @related = $mousse->fetch_related("Hearty russian beet soup");
is_deeply([sort map { $_->title } @related], [
           'French onion soup coca-cola',
          'Hearty soup mix',
          'Italian minestrone soup coca-cola',
          'Raisin puree',
          'Russian beef stroganoff coca-cola',
          'Russian refresher mix',
]);

@related = $mousse->fetch_related_keys("Hearty russian beet soup");
is_deeply([sort @related], [
          'French onion soup coca-cola',
          'Hearty soup mix',
          'Italian minestrone soup coca-cola',
          'Raisin puree',
          'Russian beef stroganoff coca-cola',
          'Russian refresher mix',
]);

$recipe = $mousse->fetch("Chiles rellenos casserole");
is($recipe->title, "Chiles rellenos casserole");

@related = $mousse->fetch_related("Chiles rellenos casserole");
is_deeply([sort map { $_->title } @related], [
          'Baked apple zapata',
          'Chinese pepper steak coca-cola',
          'Garden vegetable mix',
          'German sauerbraten coca-cola',
          'Grecian green beans coca-cola',
          'Greek stew',
          'Mexican meat mix',
          'Mexican rice mix',
          'Russian beef stroganoff coca-cola',
          'Sweet potato-currant mini bundt cakes',
          'Vegetable dip mix',
          'Vegetarian rice mix'
]);

@related = $mousse->fetch_related_keys("Chiles rellenos casserole");
is_deeply([sort @related], [
          'Baked apple zapata',
          'Chinese pepper steak coca-cola',
          'Garden vegetable mix',
          'German sauerbraten coca-cola',
          'Grecian green beans coca-cola',
          'Greek stew',
          'Mexican meat mix',
          'Mexican rice mix',
          'Russian beef stroganoff coca-cola',
          'Sweet potato-currant mini bundt cakes',
          'Vegetable dip mix',
          'Vegetarian rice mix'
]);

$recipe = $mousse->fetch("Crumb topping mix");
is($recipe->title, "Crumb topping mix");

@related = $mousse->fetch_related("Crumb topping mix");
is_deeply([sort map { $_->title } @related], [
          'Cookie crumb crust mix'
]);

@related = $mousse->fetch_related_keys("Crumb topping mix");
is_deeply([sort @related], [
          'Cookie crumb crust mix'
]);

my @search = $mousse->search("crumb");
is_deeply([sort map { $_->title } @search ], [
  'Cookie crumb crust mix',
  'Crumb topping mix',
]);

@search = $mousse->search("crumb +topping");
is_deeply([sort map { $_->title } @search ], [
  'Crumb topping mix',
]);

@search = $mousse->search("crumb -topping");
is_deeply([sort map { $_->title } @search ], [
  'Cookie crumb crust mix',
]);

@search = $mousse->search_keys("italian");
is_deeply([sort @search ], [
  'Italian cooking sauce mix',
  'Italian meat sauce mix',
  'Italian minestrone soup coca-cola',
]);

@search = $mousse->search_keys("italiaan soos");
is_deeply([sort @search], [
  'Italian cooking sauce mix',
  'Italian meat sauce mix',
]);

sub stemmer {
  my $words = lc shift;
  my @words = uniq(split / /, $words);
  @words = grep { defined } soundex(@words);
  return @words;
}
