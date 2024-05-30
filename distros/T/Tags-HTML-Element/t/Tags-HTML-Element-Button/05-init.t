use strict;
use warnings;

use Data::HTML::Element::Button;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Button;
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Button->new;
my $button = Data::HTML::Element::Button->new;
my $ret = $obj->init($button);
is($ret, undef, 'Init returns undef.');

# Test.
$obj = Tags::HTML::Element::Button->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "Input object must be a 'Data::HTML::Element::Button' instance.\n",
	"Input object must be a 'Data::HTML::Element::Button' instance.");
clean();

# Test.
$obj = Tags::HTML::Element::Button->new;
eval {
	$obj->init(Test::MockObject->new);
};
is($EVAL_ERROR, "Input object must be a 'Data::HTML::Element::Button' instance.\n",
	"Input object must be a 'Data::HTML::Element::Button' instance.");
clean();

# Test.
$obj = Tags::HTML::Element::Button->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Input object must be a 'Data::HTML::Element::Button' instance.\n",
	"Input object must be a 'Data::HTML::Element::Button' instance.");
clean();
