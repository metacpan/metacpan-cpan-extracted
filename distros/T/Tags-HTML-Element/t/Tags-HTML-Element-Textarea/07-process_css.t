use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Data::HTML::Element::Textarea;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Textarea;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Textarea->new(
	'no_css' => 1,
);
my $ret = $obj->process_css;
is($ret, undef, 'No css mode.');

# Test.
my $css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Element::Textarea->new(
	'css' => $css,
);
my $textarea = Data::HTML::Element::Textarea->new;
$obj->init($textarea);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', 'textarea'],
		['d', 'width', '100%'],
		['d', 'padding', '12px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'display', 'inline-block'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '4px'],
		['d', 'box-sizing', 'border-box'],
		['e'],
	],
	'Get CSS::Struct code (default).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Element::Textarea->new(
	'css' => $css,
);
$textarea = Data::HTML::Element::Textarea->new(
	'css_class' => 'foo',
);
$obj->init($textarea);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', 'textarea.foo'],
		['d', 'width', '100%'],
		['d', 'padding', '12px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'display', 'inline-block'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '4px'],
		['d', 'box-sizing', 'border-box'],
		['e'],
	],
	'Get CSS::Struct code (with CSS class).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Element::Textarea->new(
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
$obj = Tags::HTML::Element::Textarea->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();
