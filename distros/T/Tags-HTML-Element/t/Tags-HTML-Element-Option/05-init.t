use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Option;
use Test::MockObject;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Option->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Option object must be a 'Data::HTML::Element::Option' instance.\n",
	"Option object must be a 'Data::HTML::Element::Option' instance.");
clean();

# Test.
$obj = Tags::HTML::Element::Option->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "Option object must be a 'Data::HTML::Element::Option' instance.\n",
	"Option object must be a 'Data::HTML::Element::Option' instance.");
clean();

# Test.
$obj = Tags::HTML::Element::Option->new;
eval {
	$obj->init(Test::MockObject->new);
};
is($EVAL_ERROR, "Option object must be a 'Data::HTML::Element::Option' instance.\n",
	"Option object must be a 'Data::HTML::Element::Option' instance.");
clean();

