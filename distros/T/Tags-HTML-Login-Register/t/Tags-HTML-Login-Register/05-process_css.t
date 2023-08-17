use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Login::Register;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Login::Register->new(
	'css' => $css,
);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.form-register'],
		['d', 'width', '300px'],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'box-shadow', '0 0 10px rgba(0, 0, 0, 0.2)'],
		['e'],

		['s', '.form-register fieldset'],
		['d', 'border', 'none'],
		['d', 'padding', 0],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.form-register legend'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.form-register p'],
		['d', 'margin', 0],
		['d', 'padding', '10px 0'],
		['e'],

		['s', '.form-register label'],
		['d', 'display', 'block'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '5px'],
		['e'],

		['s', '.form-register input[type="text"]'],
		['s', '.form-register input[type="password"]'],
		['d', 'width', '100%'],
		['d', 'padding', '8px'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '3px'],
		['e'],

		['s', '.form-register button[type="submit"]'],
		['d', 'width', '100%'],
		['d', 'padding', '10px'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', '#fff'],
		['d', 'border', 'none'],
		['d', 'border-radius', '3px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', '.form-register button[type="submit"]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', '.form-register .messages'],
		['d', 'text-align', 'center'],
		['e'],
	],
	'Form CSS without message types.',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Login::Register->new(
	'css' => $css,
);
$obj->process_css({
	'error' => 'red',
	'info' => 'green',
});
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.form-register'],
		['d', 'width', '300px'],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'box-shadow', '0 0 10px rgba(0, 0, 0, 0.2)'],
		['e'],

		['s', '.form-register fieldset'],
		['d', 'border', 'none'],
		['d', 'padding', 0],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.form-register legend'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.form-register p'],
		['d', 'margin', 0],
		['d', 'padding', '10px 0'],
		['e'],

		['s', '.form-register label'],
		['d', 'display', 'block'],
		['d', 'font-weight', 'bold'],
		['d', 'margin-bottom', '5px'],
		['e'],

		['s', '.form-register input[type="text"]'],
		['s', '.form-register input[type="password"]'],
		['d', 'width', '100%'],
		['d', 'padding', '8px'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '3px'],
		['e'],

		['s', '.form-register button[type="submit"]'],
		['d', 'width', '100%'],
		['d', 'padding', '10px'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', '#fff'],
		['d', 'border', 'none'],
		['d', 'border-radius', '3px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', '.form-register button[type="submit"]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', '.form-register .messages'],
		['d', 'text-align', 'center'],
		['e'],

		['s', '.error'],
		['d', 'color', 'red'],
		['e'],

		['s', '.info'],
		['d', 'color', 'green'],
		['e'],
	],
	'Form CSS with message types.',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Login::Register->new(
	'css' => $css,
);
eval {
	$obj->process_css('bad');
};
is($EVAL_ERROR, "Message types must be a hash reference.\n",
	"Message types must be a hash reference.");
clean();

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Login::Register->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n",
	"Parameter 'css' isn't defined.");
clean();
