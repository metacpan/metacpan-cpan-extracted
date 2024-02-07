use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Form;
use Test::MockObject;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Form->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Form object must be a 'Data::HTML::Element::Form' instance.\n",
	"Form object must be a 'Data::HTML::Element::Form' instance (bad).");
clean();

# Test.
$obj = Tags::HTML::Element::Form->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "Form object must be a 'Data::HTML::Element::Form' instance.\n",
	"Form object must be a 'Data::HTML::Element::Form' instance (undef).");
clean();

# Test.
$obj = Tags::HTML::Element::Form->new;
my $form = Test::MockObject->new;
eval {
	$obj->init($form);
};
is($EVAL_ERROR, "Form object must be a 'Data::HTML::Element::Form' instance.\n",
	"Form object must be a 'Data::HTML::Element::Form' instance (bad object).");
clean();
