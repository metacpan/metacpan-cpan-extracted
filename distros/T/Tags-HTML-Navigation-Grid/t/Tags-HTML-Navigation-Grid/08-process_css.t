use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Data::Navigation::Item;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Navigation::Grid;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Navigation::Grid->new(
	'css' => $css,
);
my @data = (
	Data::Navigation::Item->new(
		'title' => 'Item #1',
	),
);
$obj->init(\@data);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.navigation'],
		['d', 'display', 'flex'],
		['d', 'flex-wrap', 'wrap'],
		['d', 'gap', '20px'],
		['d', 'padding', '20px'],
		['d', 'justify-content', 'center'],
		['e'],

		['s', '.nav-item'],
		['d', 'display', 'flex'],
		['d', 'flex-direction', 'column'],
		['d', 'align-items', 'center'],
		['d', 'border', '2px solid #007BFF'],
		['d', 'border-radius', '15px'],
		['d', 'padding', '15px'],
		['d', 'width', '200px'],
		['e'],

		['s', '.nav-item img'],
		['d', 'width', '100px'],
		['d', 'height', '100px'],
		['e'],

		['s', '.nav-item div.title'],
		['d', 'margin', '10px 0'],
		['d', 'font-family', 'sans-serif'],
		['d', 'font-weight', 'bold'],
		['e'],

		['s', '.nav-item '],
		['d', 'text-align', 'center'],
		['d', 'font-family', 'sans-serif'],
		['e'],
	],
	'Navigation CSS code (default).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Navigation::Grid->new(
	'css' => $css,
	'css_class' => 'my-navigation',
);
@data = (
	Data::Navigation::Item->new(
		'title' => 'Item #1',
	),
);
$obj->init(\@data);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.my-navigation'],
		['d', 'display', 'flex'],
		['d', 'flex-wrap', 'wrap'],
		['d', 'gap', '20px'],
		['d', 'padding', '20px'],
		['d', 'justify-content', 'center'],
		['e'],

		['s', '.nav-item'],
		['d', 'display', 'flex'],
		['d', 'flex-direction', 'column'],
		['d', 'align-items', 'center'],
		['d', 'border', '2px solid #007BFF'],
		['d', 'border-radius', '15px'],
		['d', 'padding', '15px'],
		['d', 'width', '200px'],
		['e'],

		['s', '.nav-item img'],
		['d', 'width', '100px'],
		['d', 'height', '100px'],
		['e'],

		['s', '.nav-item div.title'],
		['d', 'margin', '10px 0'],
		['d', 'font-family', 'sans-serif'],
		['d', 'font-weight', 'bold'],
		['e'],

		['s', '.nav-item '],
		['d', 'text-align', 'center'],
		['d', 'font-family', 'sans-serif'],
		['e'],
	],
	'Navigation CSS code (explicit CSS class).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Navigation::Grid->new(
	'css' => $css,
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply($ret_ar, [], 'Navigation HTML code (no init, no code).');

# Test.
$obj = Tags::HTML::Navigation::Grid->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n",
	"Parameter 'css' isn't defined.");
clean();
