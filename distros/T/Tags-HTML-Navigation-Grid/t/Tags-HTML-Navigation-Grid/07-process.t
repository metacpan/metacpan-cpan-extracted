use strict;
use warnings;

use Data::Navigation::Item;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Navigation::Grid;
use Tags::Output::Structure;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Navigation::Grid->new(
	'tags' => $tags,
);
my @data = (
	Data::Navigation::Item->new(
		'title' => 'Item #1',
	),
);
$obj->init(\@data);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'nav'],
		['a', 'class', 'navigation'],
		['b', 'div'],
		['a', 'class', 'nav-item'],
		['b', 'div'],
		['a', 'class', 'title'],
		['d', 'Item #1'],
		['e', 'div'],
		['e', 'div'],
		['e', 'nav'],
	],
	'Navigation HTML code (only title).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Navigation::Grid->new(
	'tags' => $tags,
);
@data = (
	Data::Navigation::Item->new(
		'class' => 'my-class',
		'desc' => 'This is description',
		'image' => '/image.png',
		'location' => 'https://example.com',
		'title' => 'Item #1',
	),
);
$obj->init(\@data);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'nav'],
		['a', 'class', 'navigation'],
		['b', 'div'],
		['a', 'class', 'my-class'],
		['b', 'a'],
		['a', 'href', 'https://example.com'],
		['b', 'img'],
		['a', 'src', '/image.png'],
		['a', 'alt', 'Item #1'],
		['e', 'img'],
		['b', 'div'],
		['a', 'class', 'title'],
		['d', 'Item #1'],
		['e', 'div'],
		['e', 'a'],
		['b', 'p'],
		['d', 'This is description'],
		['e', 'p'],
		['e', 'div'],
		['e', 'nav'],
	],
	'Navigation HTML code (title, desc, link, class, image).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Navigation::Grid->new(
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply($ret_ar, [], 'Navigation HTML code (no init, no code).');

# Test.
$obj = Tags::HTML::Navigation::Grid->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n",
	"Parameter 'tags' isn't defined.");
clean();
