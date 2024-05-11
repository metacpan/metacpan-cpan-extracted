use strict;
use warnings;

use Data::Navigation::Item;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Navigation::Grid;
use Test::MockObject;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Navigation::Grid->new;
my @data = (
	Data::Navigation::Item->new(
		'title' => 'Item #1',
	),
);
my $ret = $obj->init(\@data);
is($ret, undef, 'Run of init (with callback).');

# Test.
$obj = Tags::HTML::Navigation::Grid->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "Bad reference to array with items.\n",
	"Bad reference to array with items (no args.");
clean();

# Test.
$obj = Tags::HTML::Navigation::Grid->new;
eval {
	$obj->init([Test::MockObject->new]);
};
is($EVAL_ERROR, "Item object must be a 'Data::Navigation::Item' instance.\n",
	"Item object must be a 'Data::Navigation::Item' instance (bad instance).");
clean();

# Test.
$obj = Tags::HTML::Navigation::Grid->new;
eval {
	$obj->init(['foo']);
};
is($EVAL_ERROR, "Item object must be a 'Data::Navigation::Item' instance.\n",
	"Item object must be a 'Data::Navigation::Item' instance (foo).");
clean();

# Test.
$obj = Tags::HTML::Navigation::Grid->new;
eval {
	$obj->init([undef]);
};
is($EVAL_ERROR, "Item object must be a 'Data::Navigation::Item' instance.\n",
	"Item object must be a 'Data::Navigation::Item' instance (undef).");
clean();
