use v5.26;
use warnings;

use Test2::V0;

use Mojolicious::Lite;

use Data::Transfigure;
use Data::Transfigure::Default;
use Test::Mojo;

use experimental qw(signatures);

plugin('Data::Transfigure');

my $t = Test::Mojo->new();

my $transfig = Data::Transfigure->new();
$transfig->add_transfigurator_at(
  "/id" => Data::Transfigure::Default->new(
    handler => sub($data) {
      1000;
    }
  )
);

get(
  "/book/:id" => sub($c) {
    $c->render(json => {id => 1, author_id => 2, created_at => '2024-05-05T05:05:05'});
  }
);

get(
  "/books/:id" => sub($c) {
    $c->render(json => {id => 1, author_id => 2, created_at => '2024-05-05T05:05:05'}, transfigurator => $transfig);
  }
);

$t->get_ok("/book/1")->content_is('{"authorID":"2","createdAt":"2024-05-05T05:05:05","id":"1"}');

$t->get_ok("/books/1")->content_is('{"author_id":"2","created_at":"2024-05-05T05:05:05","id":1000}');

done_testing;
