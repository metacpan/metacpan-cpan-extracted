use strict;
use warnings;

use Data::HTML::Element::Input;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Input;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Input->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Input object must be a 'Data::HTML::Element::Input' instance.\n",
	"Input object must be a 'Data::HTML::Element::Input' instance.");
clean();
