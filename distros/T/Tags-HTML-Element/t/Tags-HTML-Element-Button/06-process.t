use strict;
use warnings;

use Data::HTML::Element::Button;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Button;
use Tags::Output::Structure;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Element::Button->new(
	'tags' => $tags,
);
my $button = Data::HTML::Element::Button->new;
$obj->init($button);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'button'],
		['a', 'type', 'button'],
		['e', 'button'],
	],
	'Get Tags code (default).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::Button->new(
	'tags' => $tags,
);
$button = Data::HTML::Element::Button->new(
	'css_class' => 'foo',
	'name' => 'button-name',
	'value' => 'button value',
);
$obj->init($button);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'button'],
		['a', 'type', 'button'],
		['a', 'class', 'foo'],
		['a', 'name', 'button-name'],
		['a', 'value', 'button value'],
		['e', 'button'],
	],
	'Get Tags code (with CSS class, name and value).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::Button->new(
	'tags' => $tags,
);
$button = Data::HTML::Element::Button->new(
	'autofocus' => 1,
	'disabled' => 1,
);
$obj->init($button);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'button'],
		['a', 'type', 'button'],
		['a', 'autofocus', 'autofocus'],
		['a', 'disabled', 'disabled'],
		['e', 'button'],
	],
	'Get Tags code (with boolean values).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::Button->new(
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Get Tags code (without initialization).',
);

# Test.
$obj = Tags::HTML::Element::Button->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();
