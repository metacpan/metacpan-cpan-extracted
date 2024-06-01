use strict;
use warnings;

use Data::HTML::Element::Textarea;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Textarea;
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Textarea->new;
my $textarea = Data::HTML::Element::Textarea->new;
my $ret = $obj->init($textarea);
is($ret, undef, 'Init returns undef.');

# Test.
$obj = Tags::HTML::Element::Textarea->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "Textarea object must be a 'Data::HTML::Element::Textarea' instance.\n",
	"Textarea object must be a 'Data::HTML::Element::Textarea' instance.");
clean();

# Test.
$obj = Tags::HTML::Element::Textarea->new;
eval {
	$obj->init(Test::MockObject->new);
};
is($EVAL_ERROR, "Textarea object must be a 'Data::HTML::Element::Textarea' instance.\n",
	"Textarea object must be a 'Data::HTML::Element::Textarea' instance.");
clean();

# Test.
$obj = Tags::HTML::Element::Textarea->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Textarea object must be a 'Data::HTML::Element::Textarea' instance.\n",
	"Textarea object must be a 'Data::HTML::Element::Textarea' instance.");
clean();
