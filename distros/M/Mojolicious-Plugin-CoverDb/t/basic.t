use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CoverDb' => { dir => 't/fake_cover_db', route => 'foo' };

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')
  ->status_is(200)
  ->content_is('Hello Mojo!');

$t->get_ok('/coverdb/')
  ->status_is(404);

$t->get_ok('/foo/')
  ->status_is(200)
  ->text_is('a' => 'test.html')
  ->text_is('a[href="/foo/test.html"]' => 'test.html');

$t->get_ok('/foo/test.html')
  ->status_is(200)
  ->content_is("foobarbaz\n");

done_testing();
