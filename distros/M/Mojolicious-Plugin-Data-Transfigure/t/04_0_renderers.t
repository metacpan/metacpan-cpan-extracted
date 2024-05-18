use v5.26;
use warnings;

use Test2::V0;

use Mojolicious::Lite;

use Data::Transfigure::Value;
use Mojo::JSON qw(encode_json);
use Test::Mojo;

use experimental qw(signatures);

my $str  = 'some string';
my $book = {
  id          => 4,
  created_at  => '2024-05-05T05:05:05',
  updated_at  => undef,
  sneakySnake => "true",
};

my $vt = Data::Transfigure::Value->new(
  value   => $str,
  handler => sub($data) {
    ">>>$data<<<";
  }
);

my $t = Test::Mojo->new();

get(
  "/text" => sub($c) {
    $c->render(text => $str);
  }
);
get(
  "/json" => sub($c) {
    $c->render(json => $book);
  }
);

plugin('Data::Transfigure');
app->transfig->output->add_transfigurators($vt);

# content is unchanged
$t->get_ok("/text")->content_is($str);
$t->get_ok("/json")->content_is('{"createdAt":"2024-05-05T05:05:05","id":"4","sneakySnake":"true","updatedAt":null}');

done_testing;
