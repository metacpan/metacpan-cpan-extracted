use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
unshift @INC, $data->dir('ex1')->s;
require Schema::Foo;
my $obj = Schema::Foo->new;
isa_ok($obj, 'Schema::Foo');

# Test.
unshift @INC, $data->up->dir('ex1')->s;
require Schema::Foo;
$obj = Schema::Foo->new('version' => '0.1.1');
isa_ok($obj, 'Schema::Foo');

# Test.
unshift @INC, $data->up->dir('ex1')->s;
require Schema::Foo;
eval {
	Schema::Foo->new('version' => '0.1');
};
is($EVAL_ERROR, "Schema version has bad format.\n",
	"Schema version has bad format.");
clean();

# Test.
unshift @INC, $data->up->dir('ex2')->s;
require Schema::Bar;
eval {
	Schema::Bar->new('version' => '0.1.0');
};
is($EVAL_ERROR, "Cannot load Schema module.\n",
	"Cannot load Schema module (no version module).");
clean();

# Test.
unshift @INC, $data->up->dir('ex3')->s;
require Schema::Baz;
eval {
	Schema::Baz->new('version' => '0.1.0');
};
is($EVAL_ERROR, "We need to implement distribution file with Schema versions.\n",
	"We need to implement distribution file with Schema versions (no _versions_file() implemented).");
clean();
