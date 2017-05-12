use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

my $module = 'Mojolicious::Plugin::RESTful';
use_ok($module);

plugin 'RESTful';

#
# Default REST methods
#
my $r = app->routes->restful('Person');

is($r->name, 'person', "NO method setted");

ok(app->routes->find($_), "Route $_") for qw(
  people_list people_create people_options
  people_search people_count
  person_update person_delete person_patch
  person_retrieve person_options
);

#
# Specific methods
#

is(
  app->routes->restful(
    name => 'Cat', methods => 'lc', nonresource => { search => 'get' },
  )->name,
  'cats',
  "collection"
);
ok(app->routes->find($_), "Route $_") for qw(cats_list cats_create cats_search);
ok((not defined  app->routes->find($_)), "No route $_") for qw(
cat_retrieve cat_update cat_delete cat_patch cat_options cats_options cats_count
);

#
# Nested REST url with root enabled
#
is(
  app->routes->restful(
    name => 'Family'
  )->restful(
    name => 'Member'
  )->name,
  'family_member'
);

map {
  ok(app->routes->find($_), "Nested route $_")
} qw(families_list families_create family_retrieve
family_update family_patch family_delete
family_members_list family_members_create
family_member_retrieve family_member_update
family_member_patch family_member_patch
members_list members_create
member_retrieve member_update
member_update member_delete
);

#
# Nested REST url with root disabled
#

app->routes->restful(name => 'tree')->restful(name => 'leaf', root => '');

map {
  ok((not defined app->routes->find($_)), "No root route $_ in nested routes")
} qw (
  leaf_retrieve leaf_update leaf_delete leaf_patch leaf_options
);

done_testing;
