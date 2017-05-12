use Mojo::Base -strict;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

use lib '../lib';

use_ok('Mojolicious::Plugin::Util::Endpoint::endpoints');

get '/test' => sub {
  shift->render(text => 'Not mounted.');
};

plugin Mount => { '/mounted' => app->home . '/endpoint-mounted.pl' };

my $t = Test::Mojo->new;

$t->get_ok('/test')->content_is('Not mounted.');

$t->get_ok('/mounted/test')->content_is('Mounted.');

$t->get_ok('/mounted/probe')->content_is('Mounted Endpoint.');

my $app = $t->app;

$t->get_ok('/mounted/get-ep')->content_like(qr{/mounted/probe$});
$t->get_ok('/mounted/get-url')->content_like(qr{/mounted/probe$});

done_testing;
