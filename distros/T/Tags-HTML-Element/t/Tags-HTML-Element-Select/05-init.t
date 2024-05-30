use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Select;
use Test::MockObject;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Select->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Select object must be a 'Data::HTML::Element::Select' instance.\n",
	"Select object must be a 'Data::HTML::Element::Select' instance.");
clean();

# Test.
$obj = Tags::HTML::Element::Select->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "Select object must be a 'Data::HTML::Element::Select' instance.\n",
	"Select object must be a 'Data::HTML::Element::Select' instance.");
clean();

# Test.
$obj = Tags::HTML::Element::Select->new;
eval {
	$obj->init(Test::MockObject->new);
};
is($EVAL_ERROR, "Select object must be a 'Data::HTML::Element::Select' instance.\n",
	"Select object must be a 'Data::HTML::Element::Select' instance.");
clean();

