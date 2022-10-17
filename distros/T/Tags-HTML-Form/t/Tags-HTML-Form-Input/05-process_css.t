use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Data::HTML::Form::Input;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Form::Input;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Form::Input->new(
	'css' => $css,
);
my $input = Data::HTML::Form::Input->new(
	'value' => 'Custom save',
	'type' => 'submit',
);
$obj->process_css($input);
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', 'input[type=submit]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', 'input[type=submit]'],
		['d', 'width', '100%'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'padding', '14px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'border', 'none'],
		['d', 'border-radius', '4px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', 'input'],
		['d', 'width', '100%'],
		['d', 'padding', '12px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'display', 'inline-block'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '4px'],
		['d', 'box-sizing', 'border-box'],
		['e'],
	],
	'Input CSS code (without css class).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Form::Input->new(
	'css' => $css,
);
$input = Data::HTML::Form::Input->new(
	'css_class' => 'form-input',
	'value' => 'Custom save',
	'type' => 'submit',
);
$obj->process_css($input);
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', 'input.form-input[type=submit]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', 'input.form-input[type=submit]'],
		['d', 'width', '100%'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'padding', '14px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'border', 'none'],
		['d', 'border-radius', '4px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', 'input.form-input'],
		['d', 'width', '100%'],
		['d', 'padding', '12px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'display', 'inline-block'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '4px'],
		['d', 'box-sizing', 'border-box'],
		['e'],
	],
	'Input CSS code (with css class).',
);

# Test.
$obj = Tags::HTML::Form::Input->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n",
	"Parameter 'css' isn't defined.");
clean();
