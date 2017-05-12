use Test::More;
use Test::Mojo;
use lib 't/lib';

my $module = 'Mojolicious::Plugin::RESTful';
use_ok($module);

my $t = Test::Mojo->new("MyRest");

my $routes = $t->app->routes;

my $person_eric = {
  name => "Eric Lee",
  id => "eric",
  age => 18
};

my $person_zoe = {
  name => "Zoe Cute",
  id => 'zoe',
  age => '22'
};

my $person_eric_new = {
  name => "Erics Wong",
  id => "erics",
  age => "37"
};
# people_list
$t->get_ok("/people")->status_is(200)->json_is('/0' => $person_eric);

# people_create
$t->post_ok("/people" => form => $person_zoe )->status_is(200)->json_is($person_zoe);

# people_header
$t->head_ok("/people")->status_is(200)->content_is('');

# people_options
$t->options_ok("/people")->status_is(200)->header_is(Allow => 'GET POST');

# person_retrieve
$t->get_ok("/people/eric")->status_is(200)->json_is($person_eric);

# person_update
$t->put_ok("/people/eric" => form => $person_eric_new)->status_is(200)->json_is($person_eric_new);

# person_delete
$t->delete_ok("/people/eric")->status_is(200)->get_ok("/people/eric")->status_is(404);

# person_patch
$t->patch_ok("/people/zoe" => form => {age => 23})->status_is(200)->get_ok("/people/zoe")->json_is("/age" => 23);

# person_options
$t->options_ok("/people/zoe")->header_is("Allow" => 'GET POST PUT PATCH DELETE');

my $eric_cat_brown = {
  id => 'brown',
  color => 'brown',
  owner => 'eric',
};

# person_cats_options
$t->options_ok('/people/eric/cats')->status_is(200);

# person_cat_options
$t->options_ok('/people/eric/cats/brown');

# person_cats_create
$t->post_ok("/people/eric/cats" => form => $eric_cat_brown)->status_is(200);

# person_cats_list
$t->get_ok('/people/eric/cats')->status_is(200)->json_is('/0' => $eric_cat_brown);

# person_cat_retrieve
$t->get_ok('/people/eric/cats/brown')->json_is($eric_cat_brown);

# person_cat_update
$t->put_ok('/people/eric/cats/brown' => form => { color => 'brown black'})->status_is(200);
$t->get_ok('/people/eric/cats/brown')->json_is('/color' => 'brown black');

# person_cat_patch
$t->patch_ok('/people/eric/cats/brown' => form => { color => 'brown'})->status_is(200);
$t->get_ok('/people/eric/cats/brown')->json_is('/color' => 'brown');

# person_cat_delete
$t->delete_ok('/people/eric/cats/brown')->status_is(200);
$t->get_ok('/people/eric/cats/brown')->status_is(404);

done_testing;

