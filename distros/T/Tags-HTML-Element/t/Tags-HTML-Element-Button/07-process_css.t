use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Data::HTML::Element::Button;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Button;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Element::Button->new(
	'css' => $css,
);
my $button = Data::HTML::Element::Button->new;
$obj->init($button);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', 'button'],
		['d', 'width', '100%'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'padding', '14px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'border', 'none'],
		['d', 'border-radius', '4px'],
		['d', 'cursor', 'pointer'],
		['e'],
		['s', 'button:hover'],
		['d', 'background-color', '#45a049'],
		['e'],
	],
	'Get CSS::Struct code (defaults).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Element::Button->new(
	'css' => $css,
);
$button = Data::HTML::Element::Button->new(
	'css_class' => 'foo',
);
$obj->init($button);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', 'button.foo'],
		['d', 'width', '100%'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'padding', '14px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'border', 'none'],
		['d', 'border-radius', '4px'],
		['d', 'cursor', 'pointer'],
		['e'],
		['s', 'button.foo:hover'],
		['d', 'background-color', '#45a049'],
		['e'],
	],
	'Get CSS::Struct code (with CSS class).',
);

# Test.
$obj = Tags::HTML::Element::Button->new(
	'no_css' => 1,
);
my $ret = $obj->process_css;
is($ret, undef, 'No css mode.');

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Element::Button->new(
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
$obj = Tags::HTML::Element::Button->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();
