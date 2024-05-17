use v5.26;
use warnings;

use Test2::V0;

use Mojolicious::Lite;

use experimental qw(signatures);

$ENV{MOJO_LOG_LEVEL} = 'fatal';

plugin('Authorization::AccessControl');

my $current_user = {id => 1};

app->authz->role->grant(Book => list => {visible => 1})->grant(Book => read => {own => 1})->grant(Book => edit => {own => 1})
  ->grant(Book => delete => {own => 1});

app->authz->dynamic_attrs(
  Book => sub($c, $ctx) {
    {
      book_id => $ctx->{id},
      own     => $ctx->{owner_id} == $current_user->{id}
    }
  }
);

is(
  app->authz->request(Book => 'read')->yield(
    sub() {
      {id => 1, owner_id => 1}
    }
    )->is_granted,
  bool(1),
  'check dynamic read'
);

ok(
  dies {
    app->authz->request(Book => 'list')->with_attributes({visible => 1})->yield(
      sub() {
        [{id => 1, owner_id => 1}, {id => 2, owner_id => 1}, {id => 3, owner_id => 2}]
      }
      )->is_granted
  },
  'pass context to inapplicable dynamic attr handler'
);

app->authz->dynamic_attrs(Book => list => undef);

is(
  app->authz->request(Book => 'list')->yield(
    sub() {
      [{id => 1, owner_id => 1}, {id => 2, owner_id => 1}, {id => 3, owner_id => 2}]
    }
    )->is_granted,
  bool(0),
  'block access to single-entity dynamic attr handler'
);

is(
  app->authz->request(Book => 'list')->with_attributes({visible => 1})->yield(
    sub() {
      [{id => 1, owner_id => 1}, {id => 2, owner_id => 1}, {id => 3, owner_id => 2}]
    }
    )->is_granted,
  bool(1),
  'supply static attributes'
);

done_testing;
