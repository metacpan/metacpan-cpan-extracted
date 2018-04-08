#! perl -w

use Test::Most;

use Mojolicious::Lite;
use Test::Mojo;

use_ok('Mojolicious::Plugin::JSONAPI');

plugin 'JSONAPI';

my $t = Test::Mojo->new();

is($t->app->types->type('json'), 'application/vnd.api+json', 'correct json mime types added to app');

done_testing;
