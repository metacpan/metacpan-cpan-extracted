use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CSPHeader', csp => "default-src 'none'; font-src 'self'; img-src 'self' data:; style-src 'self'";

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')
  ->status_is(200)
  ->header_is('Content-Security-Policy' => "default-src 'none'; font-src 'self'; img-src 'self' data:; style-src 'self'")
  ->content_is('Hello Mojo!');

$t = $t->get_ok('/something.js')
  ->status_is(200)
  ->header_is('Content-Security-Policy' => "default-src 'none'; font-src 'self'; img-src 'self' data:; style-src 'self'")
  ->content_is("alert('hello!');\n");

done_testing();
