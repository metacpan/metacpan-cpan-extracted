use v5.26;
use warnings;

use Test2::V0;

use Mojolicious::Lite;

use experimental qw(signatures);

$ENV{MOJO_LOG_LEVEL} = 'fatal';

helper("authn.current_user_roles" => sub($c) {[qw(admin user)]});

# default get_roles implementation using `current_user_roles` helper
plugin('Authorization::AccessControl');

app->authz->role('admin')->grant(User => 'list');
app->authz->role('user')->grant(Book => 'list');
app->authz->role->grant(Book => 'create');

is(app->authz->request->with_resource('User')->with_action('list')->permitted,   bool(1), 'check admin role');
is(app->authz->request->with_resource('Book')->with_action('list')->permitted,   bool(1), 'check user role');
is(app->authz->request->with_resource('Book')->with_action('create')->permitted, bool(1), 'check role-less access (1)');

# no get_roles function (all requests run role-less)
plugin(
  'Authorization::AccessControl' => {
    get_roles => undef
  }
);

is(app->authz->request->with_resource('User')->with_action('list')->permitted,   bool(0), 'check admin role not present');
is(app->authz->request->with_resource('Book')->with_action('list')->permitted,   bool(0), 'check user role not present');
is(app->authz->request->with_resource('Book')->with_action('create')->permitted, bool(1), 'check role-less access (2)');

plugin(
  'Authorization::AccessControl' => {
    get_roles => sub($c) {['user']}
  }
);

is(app->authz->request->with_resource('User')->with_action('list')->permitted,   bool(0), 'check admin role not present');
is(app->authz->request->with_resource('Book')->with_action('list')->permitted,   bool(1), 'check user role');
is(app->authz->request->with_resource('Book')->with_action('create')->permitted, bool(1), 'check role-less access (3)');

done_testing;
