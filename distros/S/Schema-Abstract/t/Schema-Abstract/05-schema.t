use strict;
use warnings;

use File::Object;
use Schema::Abstract;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
unshift @INC, $data->dir('ex1')->s;
require Schema::Foo;
my $obj = Schema::Foo->new;
my $ret = $obj->schema;
is($ret, 'Schema::Foo::0_2_0', 'Get schema module (latest).');

# Test.
unshift @INC, $data->dir('ex1')->s;
require Schema::Foo;
$obj = Schema::Foo->new('version' => '0.1.1');
$ret = $obj->schema;
is($ret, 'Schema::Foo::0_1_1', 'Get schema module (0.1.1).');
