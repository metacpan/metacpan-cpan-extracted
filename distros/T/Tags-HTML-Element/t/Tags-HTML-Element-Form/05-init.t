use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Form;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Form->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Form item must be a 'Data::HTML::Element::Input', 'Data::HTML::Element::Textarea' or 'Data::HTML::Element::Select' instance.\n",
	"Form item must be a 'Data::HTML::Element::Input', 'Data::HTML::Element::Textarea' or 'Data::HTML::Element::Select' instance.");
clean();
