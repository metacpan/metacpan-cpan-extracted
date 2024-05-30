use strict;
use warnings;

use Data::HTML::Element::Option;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Option;
use Tags::Output::Structure;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $option = Data::HTML::Element::Option->new;
my $obj = Tags::HTML::Element::Option->new(
	'tags' => $tags,
);
$obj->init($option);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'option'],
		['e', 'option'],
	],
	'Get Tags code (default).',
);

# Test.
$tags = Tags::Output::Structure->new;
$option = Data::HTML::Element::Option->new(
	'id' => 'one',
	'data' => ['Option'],
);
$obj = Tags::HTML::Element::Option->new(
	'tags' => $tags,
);
$obj->init($option);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'option'],
		['a', 'id', 'one'],
		['d', 'Option'],
		['e', 'option'],
	],
	'Get Tags code (with id and plain data).',
);

# Test.
$tags = Tags::Output::Structure->new;
$option = Data::HTML::Element::Option->new(
	'id' => 'one',
	'data' => [['d', 'Option']],
	'data_type' => 'tags',
);
$obj = Tags::HTML::Element::Option->new(
	'tags' => $tags,
);
$obj->init($option);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'option'],
		['a', 'id', 'one'],
		['d', 'Option'],
		['e', 'option'],
	],
	'Get Tags code (with id and Tags data).',
);

# Test.
$tags = Tags::Output::Structure->new;
$option = Data::HTML::Element::Option->new(
	'id' => 'one',
	'data' => [sub {
		my $self = shift;
		$self->{'tags'}->put(['d', 'Option']);
		return;
	}],
	'data_type' => 'cb',
);
$obj = Tags::HTML::Element::Option->new(
	'tags' => $tags,
);
$obj->init($option);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'option'],
		['a', 'id', 'one'],
		['d', 'Option'],
		['e', 'option'],
	],
	'Get Tags code (with id and callback data).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::Option->new(
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
$obj = Tags::HTML::Element::Option->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();
