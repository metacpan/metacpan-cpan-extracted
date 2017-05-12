use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use Kavorka;

plugin 'Kavorka';

any '/:name' => {name => 'World'} => method ($name) {
  $self->render(text => "Hello $name!");
};

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->status_is(200)
  ->content_is('Hello World!');

$t->get_ok('/Joel')
  ->status_is(200)
  ->content_is('Hello Joel!');

done_testing;

