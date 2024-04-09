use strict;
use warnings;

use Tags::Utils qw(encode_char_entities);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $string = 'a<a&a'."\240a";
my $ret = encode_char_entities($string);
is($ret, 'a&lt;a&amp;a&nbsp;a',
	'Encode character entities (&lt;, &amp; and &nbsp;).');

# Test.
encode_char_entities(\$string);
is($string, 'a&lt;a&amp;a&nbsp;a',
	'Encode character entities defined by reference (&lt;, &amp; and &nbsp;).');

# Test.
my @array = ('a<a', "a\240a", 'a&a', 'a&lt;a', 'a&nbsp;a', 'a&amp;a');
encode_char_entities(\@array);
is_deeply(
	\@array,
	[
		'a&lt;a',
		'a&nbsp;a',
		'a&amp;a',
		'a&lt;a',
		'a&nbsp;a',
		'a&amp;a',
	],
	'Encode character entities defined by array (&lt;, &amp; and &nbsp;).',
);
