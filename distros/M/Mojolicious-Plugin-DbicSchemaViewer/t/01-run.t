use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Test::Deep;
use Mojolicious::Lite;

use lib 't/lib';
use TestFor::DbicVisualizer::Schema;

my $schema = 'TestFor::DbicVisualizer::Schema';

plugin 'DbicSchemaViewer';

my $t = Test::Mojo->new;

$t->get_ok("/dbic-schema-viewer/$schema")->status_is(200);
my $tok = $t->get_ok("/dbic-schema-viewer/$schema")->status_is(200);

$tok->content_like(qr/for TestFor::DbicVisualizer::Schema/);
$tok->content_like(qr/missing reverse/i);

done_testing;
