use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Messages;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Messages->new(
	'css' => $css,
);
$obj->process_css({'error' => 'red'});
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.error'],
		['d', 'color', 'red'],
		['e'],
	],
	'Add error type.',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
	'css' => $css,
);
$obj->process_css({});
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Add error type (no types).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
	'css' => $css,
);
$obj->process_css();
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Add error type (undef types).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
	'css' => $css,
);
eval {
	$obj->process_css('bad');
};
is($EVAL_ERROR, "Message types must be a hash reference.\n",
	"Message types must be a hash reference.");

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Messages->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n",
	"Parameter 'css' isn't defined.");
clean();
