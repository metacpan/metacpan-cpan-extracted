use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Tree;
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Tree;

# Test.
my $obj = Tags::HTML::Tree->new;
my $tree = Tree->new('Root');
my $ret = $obj->init($tree);
is($ret, undef, 'Init returns undef.');

# Test.
$obj = Tags::HTML::Tree->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "Data object must be a 'Tree' instance.\n",
	"Data object must be a 'Tree' instance (undef).");
clean();

# Test.
$obj = Tags::HTML::Tree->new;
eval {
	$obj->init(Test::MockObject->new);
};
is($EVAL_ERROR, "Data object must be a 'Tree' instance.\n",
	"Data object must be a 'Tree' instance (object).");
clean();

# Test.
$obj = Tags::HTML::Tree->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Data object must be a 'Tree' instance.\n",
	"Data object must be a 'Tree' instance (string).");
clean();
