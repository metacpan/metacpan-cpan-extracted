use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Data::HTML::Element::A;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::A;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Element::A->new(
	'css' => $css,
);
my $anchor = Data::HTML::Element::A->new;
$obj->init($anchor);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Get CSS::Struct code (default).',
);

# Test.
$obj = Tags::HTML::Element::A->new(
	'no_css' => 1,
);
my $ret = $obj->process_css;
is($ret, undef, 'No css mode.');

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Element::A->new(
	'css' => $css,
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Get CSS::Struct code (default).',
);

# Test.
$obj = Tags::HTML::Element::A->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();
