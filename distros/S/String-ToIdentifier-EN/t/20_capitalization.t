use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestString 'is_both';

plan tests => 6 * 2;

# Capitalization is preserved.

is_both ['foo.bar'], 'fooDotBar';
is_both ['Foo.bar'], 'FooDotBar';

is_both ['foo.bar', '_'], 'foo_dot_bar';
is_both ['Foo.bar', '_'], 'Foo_dot_bar';

# If the first char is transformed, then it becomes lowercased.

is_both ['.bar'], 'dotBar';
is_both ['.bar', '_'], 'dot_bar';
