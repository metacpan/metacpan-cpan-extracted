use strict;
use warnings;

use Data::HTML::Element::Select;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Select;
use Tags::Output::Structure;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $select = Data::HTML::Element::Select->new;
my $obj = Tags::HTML::Element::Select->new(
	'tags' => $tags,
);
$obj->init($select);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'select'],
		['e', 'select'],
	],
	'Get Tags code (default).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::Select->new(
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
$obj = Tags::HTML::Element::Select->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();

