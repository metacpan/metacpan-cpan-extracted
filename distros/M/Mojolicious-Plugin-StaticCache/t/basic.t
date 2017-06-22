use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'StaticCache';

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/mojo/logo-white.png')->status_is(200)->header_is('Cache-Control' => undef);

plugin 'StaticCache' => { even_in_dev => 1 };
$t->get_ok('/mojo/logo-white.png')->status_is(200)->header_is('Cache-Control' => 'max-age=2592000, must-revalidate');

plugin 'StaticCache' => { even_in_dev => 1, max_age => 2 };
$t->get_ok('/mojo/logo-white.png')->status_is(200)->header_is('Cache-Control' => 'max-age=2, must-revalidate');

plugin 'StaticCache' => { even_in_dev => 1, cache_control => 'public' };
$t->get_ok('/mojo/logo-white.png')->status_is(200)->header_is('Cache-Control' => 'public');

plugin 'StaticCache' => { even_in_dev => 1, max_age => 2, cache_control => 'public' };
$t->get_ok('/mojo/logo-white.png')->status_is(200)->header_is('Cache-Control' => 'public');

done_testing();
