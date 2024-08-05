use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Data::HTML::Footer;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Footer;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Footer->new(
	'css' => $css,
);
my $footer = Data::HTML::Footer->new;
$obj->init($footer);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '#main'],
		['d', 'padding-bottom', '40px'],
		['e'],

		['s', 'footer'],
		['d', 'text-align', 'center'],
		['d', 'padding', '10px 0'],
		['d', 'background-color', '#f3f3f3'],
		['d', 'color', '#333'],
		['d', 'position', 'fixed'],
		['d', 'bottom', 0],
		['d', 'width', '100%'],
		['d', 'height', '40px'],
		['d', 'font-family', 'Arial, Helvetica, sans-serif'],
		['e'],
	],
	'Get CSS::Struct code (default).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Footer->new(
	'css' => $css,
);
$footer = Data::HTML::Footer->new(
	'height' => '2em',
);
$obj->init($footer);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '#main'],
		['d', 'padding-bottom', '2em'],
		['e'],

		['s', 'footer'],
		['d', 'text-align', 'center'],
		['d', 'padding', '10px 0'],
		['d', 'background-color', '#f3f3f3'],
		['d', 'color', '#333'],
		['d', 'position', 'fixed'],
		['d', 'bottom', 0],
		['d', 'width', '100%'],
		['d', 'height', '2em'],
		['d', 'font-family', 'Arial, Helvetica, sans-serif'],
		['e'],
	],
	'Get CSS::Struct code (height from data object).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Footer->new(
	'css' => $css,
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Without initialization.',
);

# Test.
$obj = Tags::HTML::Footer->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();
