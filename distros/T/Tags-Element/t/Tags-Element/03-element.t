use strict;
use warnings;

use Tags::Element qw(element);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my @ret = element('div');
is_deeply(
	\@ret,
	[
		['b', 'div'],
		['e', 'div'],
	],
	'Get div element.',
);

# Test.
@ret = element('div', {});
is_deeply(
	\@ret,
	[
		['b', 'div'],
		['e', 'div'],
	],
	'Get div element with no attributes.',
);

# Test.
@ret = element('div', [['b', 'br'], ['e', 'br']]);
is_deeply(
	\@ret,
	[
		['b', 'div'],
		['b', 'br'],
		['e', 'br'],
		['e', 'div'],
	],
	'Get div with inside Tags code.',
);

# Test.
@ret = element('div', {'id' => '_ID_'});
is_deeply(
	\@ret,
	[
		['b', 'div'],
		['a', 'id', '_ID_'],
		['e', 'div'],
	],
	'Get div with id attribute.',
);

# Test.
@ret = element('div', {'id' => '_ID_'}, [['b', 'br'], ['e', 'br']]);
is_deeply(
	\@ret,
	[
		['b', 'div'],
		['a', 'id', '_ID_'],
		['b', 'br'],
		['e', 'br'],
		['e', 'div'],
	],
	'Get div with id attribute and inside Tags code.',
);

# Test.
@ret = element('div', [['b', 'br'], ['e', 'br']], {'id' => '_ID_'});
is_deeply(
	\@ret,
	[
		['b', 'div'],
		['a', 'id', '_ID_'],
		['b', 'br'],
		['e', 'br'],
		['e', 'div'],
	],
	'Get div with id attribute and inside Tags code - another way.',
);

# Test.
@ret = element('div', 'data');
is_deeply(
	\@ret,
	[
		['b', 'div'],
		['d', 'data'],
		['e', 'div'],
	],
	'Get div with data.',
);

# Test.
@ret = element('div', 'data1', 'data2');
is_deeply(
	\@ret,
	[
		['b', 'div'],
		['d', 'data1'],
		['d', 'data2'],
		['e', 'div'],
	],
	'Get div with more data.',
);
