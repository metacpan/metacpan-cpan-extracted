package main;

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojo::File 'path';
use lib;

my $site = path(__FILE__)->sibling('site');
my $lib  = $site->child('lib')->to_string;
my $www  = $site->child('www')->to_string;
lib->import($lib);
lib->import($www);

my $t = Test::Mojo->new('Skel');
push @{ $t->app->renderer->paths }, $www;

my $app = $t->app;
my $r   = $app->routes;

$app->mode('production');
$r->get( '/500' => sub { shift->reply->exception('Division by zero!'); } );
$r->get( '/404' => sub { shift->reply->not_found; } );

$t->get_ok('/500')->status_is(500)->content_like(qr/head back to the homepage/);
$t->get_ok('/404')->status_is(404)->content_like(qr/does not exist/);

done_testing();

1;
