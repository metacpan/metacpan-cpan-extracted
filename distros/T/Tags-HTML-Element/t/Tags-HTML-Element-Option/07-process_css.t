use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Data::HTML::Element::Option;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Option;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $option = Data::HTML::Element::Option->new;
my $obj = Tags::HTML::Element::Option->new(
	'css' => $css,
);
$obj->init($option);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Get CSS::Struct code (defaults).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Element::Option->new(
	'css' => $css,
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Get CSS::Struct code (without initialization).',
);

# Test.
$obj = Tags::HTML::Element::Option->new(
	'no_css' => 1,
);
my $ret = $obj->process_css;
is($ret, undef, 'No css mode.');

# Test.
$obj = Tags::HTML::Element::Option->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();
