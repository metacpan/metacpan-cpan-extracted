use v5.26;
use warnings;

use Test2::V0;

use Mojolicious::Lite;

use experimental qw(signatures);

use Test::Mojo;
my $t = Test::Mojo->new();

plugin('Authorization::AccessControl');

# static grants
app->authz->role->grant(Book => 'read');

# insert grants for the current request only
app->hook(
  before_dispatch => sub($c) {
    $c->authz->role->grant(Book => 'delete', {book_id => 1});
  }
);

get(
  '/books' => sub($c) {
    is($c->authz->request(Book => 'read')->permitted, bool(1), 'static grant in request context');
    $c->render(text => '');
  }
);

get(
  '/book/:id' => sub($c) {
    is($c->authz->request(Book => 'delete')->with_attributes({book_id => 1})->permitted,
      bool(1), 'dynamic grant in request context');
    $c->render(text => '');
  }
);

is(app->authz->request(Book => 'read')->permitted,                                    bool(1), 'static grant');
is(app->authz->request(Book => 'delete')->with_attributes({book_id => 1})->permitted, bool(0), 'dynamic grant in static context');

$t->get_ok('/books');

is(app->authz->request(Book => 'delete')->with_attributes({book_id => 1})->permitted,
  bool(0), 'dynamic grant in static context still is not there');

$t->get_ok('/book/1');

is(app->authz->request(Book => 'delete')->with_attributes({book_id => 1})->permitted,
  bool(0), 'dynamic grant in static context still still is not there');

done_testing;
