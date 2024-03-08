use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::ChangePassword;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::ChangePassword->new(
	'css' => $css,
);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.form-change-password'],
		['d', 'width', '300px'],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'box-shadow', '0 0 10px rgba(0, 0, 0, 0.2)'],
		['e'],

		['s', '.form-change-password fieldset'],
		['d', 'border', 'none'],
		['d', 'padding', 0],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.form-change-password legend'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.form-change-password p'],
		['d', 'margin', 0],
		['d', 'padding', '10px 0'],
		['e'],

		['s', '.form-change-password label'],
		['d', 'display', 'block'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '5px'],
		['e'],

		['s', '.form-change-password input[type="text"]'],
		['s', '.form-change-password input[type="password"]'],
		['d', 'width', '100%'],
		['d', 'padding', '8px'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '3px'],
		['e'],

		['s', '.form-change-password button[type="submit"]'],
		['d', 'width', '100%'],
		['d', 'padding', '10px'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', '#fff'],
		['d', 'border', 'none'],
		['d', 'border-radius', '3px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', '.form-change-password button[type="submit"]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', '.form-change-password .messages'],
		['d', 'text-align', 'center'],
		['e'],
	],
	'ChangePassword CSS code (default class name).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::ChangePassword->new(
	'css' => $css,
);
$obj->prepare({
	'error' => 'red',
	'info' => 'blue',
});
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.form-change-password'],
		['d', 'width', '300px'],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'box-shadow', '0 0 10px rgba(0, 0, 0, 0.2)'],
		['e'],

		['s', '.form-change-password fieldset'],
		['d', 'border', 'none'],
		['d', 'padding', 0],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.form-change-password legend'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.form-change-password p'],
		['d', 'margin', 0],
		['d', 'padding', '10px 0'],
		['e'],

		['s', '.form-change-password label'],
		['d', 'display', 'block'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '5px'],
		['e'],

		['s', '.form-change-password input[type="text"]'],
		['s', '.form-change-password input[type="password"]'],
		['d', 'width', '100%'],
		['d', 'padding', '8px'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '3px'],
		['e'],

		['s', '.form-change-password button[type="submit"]'],
		['d', 'width', '100%'],
		['d', 'padding', '10px'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', '#fff'],
		['d', 'border', 'none'],
		['d', 'border-radius', '3px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', '.form-change-password button[type="submit"]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', '.form-change-password .messages'],
		['d', 'text-align', 'center'],
		['e'],

		['s', '.error'],
		['d', 'color', 'red'],
		['e'],

		['s', '.info'],
		['d', 'color', 'blue'],
		['e'],
	],
	'ChangePassword CSS code (default class name + messages).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::ChangePassword->new(
	'css' => $css,
	'css_change_password' => 'my-class',
	'width' => '50em',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.my-class'],
		['d', 'width', '50em'],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'box-shadow', '0 0 10px rgba(0, 0, 0, 0.2)'],
		['e'],

		['s', '.my-class fieldset'],
		['d', 'border', 'none'],
		['d', 'padding', 0],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.my-class legend'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.my-class p'],
		['d', 'margin', 0],
		['d', 'padding', '10px 0'],
		['e'],

		['s', '.my-class label'],
		['d', 'display', 'block'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '5px'],
		['e'],

		['s', '.my-class input[type="text"]'],
		['s', '.my-class input[type="password"]'],
		['d', 'width', '100%'],
		['d', 'padding', '8px'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '3px'],
		['e'],

		['s', '.my-class button[type="submit"]'],
		['d', 'width', '100%'],
		['d', 'padding', '10px'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', '#fff'],
		['d', 'border', 'none'],
		['d', 'border-radius', '3px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', '.my-class button[type="submit"]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', '.my-class .messages'],
		['d', 'text-align', 'center'],
		['e'],
	],
	'ChangePassword CSS code (explicit class name and width).',
);

# Test.
$obj = Tags::HTML::ChangePassword->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n",
	"Parameter 'css' isn't defined.");
clean();
