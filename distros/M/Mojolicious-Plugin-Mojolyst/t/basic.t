package MyApp::Controller::Foo;
use Mojolicious::Lite;

get '/' => {text => 'Welcome to Mojolyst!'};

package main;
use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Mojolyst' => {controllers => 'MyApp::Controller'};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Welcome to Mojolyst!');

done_testing();
