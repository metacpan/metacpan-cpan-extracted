#! perl -w

use Test::Most;

use Mojolicious::Lite;
use Test::Mojo;

use_ok('Mojolicious::Plugin::JSONAPI');

plugin 'JSONAPI';

my $t = Test::Mojo->new();

is($t->app->types->type('json'), 'application/vnd.api+json', 'correct json mime types added to app');

ok($t->app->helper('resource_document'), 'resource_document helper available');
ok($t->app->helper('resource_documents'), 'resource_documents helper available');
ok($t->app->helper('compound_resource_document'), 'compound_resource_document helper available');

done_testing;
