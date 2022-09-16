use strict;
use warnings;

use File::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
unshift @INC, $data->dir('ex1')->s;
require Schema::Foo;
my $obj = Schema::Foo->new;
my $ret = $obj->version;
is($ret, '0.2.0', 'Get version (latest).');

# Test.
unshift @INC, $data->dir('ex1')->s;
require Schema::Foo;
$obj = Schema::Foo->new('version' => '0.1.1');
$ret = $obj->version;
is($ret, '0.1.1', 'Get version (0.1.1).');
