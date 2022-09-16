use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Tags::HTML::Login::Button;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Login::Button->new(
	'css' => $css,
);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.outer'],
		['d', 'position', 'fixed'],
		['d', 'top', '50%'],
		['d', 'left', '50%'],
		['d', 'transform', 'translate(-50%, -50%)'],
		['e'],

		['s', '.login'],
		['d', 'text-align', 'center'],
		['e'],

		['s', '.login a'],
		['d', 'text-decoration', 'none'],
		['d', 'background-image', 'linear-gradient(to bottom,#fff 0,#e0e0e0 100%)'],
		['d', 'background-repeat', 'repeat-x'],
		['d', 'border', '1px solid #adadad'],
		['d', 'border-radius', '4px'],
		['d', 'color', 'black'],
		['d', 'font-family', 'sans-serif!important'],
		['d', 'padding', '15px 40px'],
		['e'],

		['s', '.login a:hover'],
		['d', 'background-color', '#e0e0e0'],
		['d', 'background-image', 'none'],
		['e'],
	],
	'Default login button CSS.',
);
