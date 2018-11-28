# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'ZipBomb', { routes => ['/wp-admin.php', '/admin/'], methods => ['get'] };

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')
  ->status_is(200)
  ->content_is('Hello Mojo!');

$t->get_ok('/wp-admin.php')
  ->status_is(200)
  ->header_is('Content-Encoding' => 'gzip')
  ->header_is('Content-Length'   => 42838)
  ->header_is('Content-Type'     => 'application/zip'); # would be 'text/html' in production

$t->get_ok('/admin/')
  ->status_is(200)
  ->header_is('Content-Encoding' => 'gzip')
  ->header_is('Content-Length'   => 42838)
  ->header_is('Content-Type'     => 'application/zip');

$t->post_ok('/wp-admin.php')
  ->status_is(404);

done_testing();
