use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::GradientIndicator;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::GradientIndicator->new(
	'css' => $css,
);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.gradient'],
		['d', 'height', '30px'],
		['d', 'width', '500px'],
		['d', 'background-color', 'red'],
		['d', 'background-image', 'linear-gradient(to right, red, orange, yellow, green, blue, indigo, violet)'],
		['e'],
	],
	'Get CSS::Struct code (default).',
);

# Test.
$obj = Tags::HTML::GradientIndicator->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();
