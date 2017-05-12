use strict;
use warnings;

use lib qw( ../lib t/lib lib);

use MyApp;
use Data::Dumper;

use Test::More;
END { done_testing(); }

use Test::Mojo;

use_ok('MyApp');

my $t = Test::Mojo->new(MyApp->new);

ok($t,'MyApp new');

my $schema = $t->app->schema;

ok($schema, 'MyApp schema');

my @sources = $schema->sources;

is(scalar(@sources),2, 'scalar @sources');

my $source = $sources[0];

ok($source, 'MyApp source');

my $table = $schema->class($source)->table;

ok($table, 'MyApp table');
