use strict;
use warnings;

use File::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
unshift @INC, $data->dir('ex1')->s;
require Schema::Data::Foo;
my $obj = Schema::Data::Foo->new;
my $ret = $obj->schema_data;
is($ret, 'Schema::Data::Foo::0_2_0', 'Get schema data module (latest).');

# Test.
unshift @INC, $data->dir('ex1')->s;
require Schema::Data::Foo;
$obj = Schema::Data::Foo->new('version' => '0.1.1');
$ret = $obj->schema_data;
is($ret, 'Schema::Data::Foo::0_1_1', 'Get schema data module (0.1.1).');
