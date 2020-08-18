use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CoverDb' => { dir => 't/cover_db' };

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')
  ->status_is(200)
  ->content_is('Hello Mojo!');

$t->get_ok('/coverdb/')
  ->status_is(200)
  ->content_is("coverage\n");

$t->get_ok('/coverdb/coverage.html')
  ->status_is(200)
  ->content_is("coverage\n");

done_testing();
