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
isa_ok($obj, 'Schema::Data::Foo');

# Test.
unshift @INC, $data->dir('ex1')->s;
require Schema::Data::Foo;
$obj = Schema::Data::Foo->new('version' => '0.1.1');
isa_ok($obj, 'Schema::Data::Foo');
