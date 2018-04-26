use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'GzipStatic';

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')
  ->status_is(200)
  ->content_is('Hello Mojo!');

$t = $t->get_ok('/something.js', { 'Accept-Encoding' => 'gzip' })
  ->status_is(200)
  ->header_is(Vary => 'Accept-Encoding')
  ->content_is("alert('hello!');\n");

done_testing();
