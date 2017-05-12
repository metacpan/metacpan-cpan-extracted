use strict;
use warnings;
use utf8;

use Test::More tests => 14;

use String::Copyright {
	format => sub { join ':', $_->[0] || '', $_->[1] || '' }
};

is_deeply copyright("© 1999 12345 Steps"),
	'1999:12345 Steps',
	'year-like owner';

is_deeply copyright("© 1999 1234 Steps"),
	'1234, 1999:Steps',
	'too-year-like owner';

is copyright("© Foo"), ':Foo', 'year-less owner';

is copyright("© , Foo"), ':Foo', 'messy owner starting with comma';

is copyright("© . Foo"), '', 'bogus owner starting with dot';

is copyright("© -Foo"), ':-Foo', 'owner starting with dash';

is copyright("© (Foo)"), ':(Foo)', 'owner starting with paranthesis';

is copyright("© ( Foo)"), '',
	'bogus owner starting with standalone paranthesis';

is copyright('© Foo (Bar) Baz'), ':Foo (Bar) Baz',
	'owner with non-first word in parenthesis';

is copyright('© Foo (Bar Baz)'), ':Foo (Bar Baz)',
	'owner with non-first words in parenthesis';

is copyright('© (Foo) Bar Baz'), ':(Foo) Bar Baz',
	'owner with first word in parenthesis';

is copyright('© Foo, all rights reserved.'), ':Foo', 'boilerplate';

TODO: {
	local $TODO = 'not yet handled';
	is copyright('© Foo, all rights reserved. Bar'), ':Foo',
		'boilerplate, then noise';

	is copyright('© Foo, all rights reserved. © Bar'), ":Foo\n:Bar",
		'boilerplate, then another copyright';
}
