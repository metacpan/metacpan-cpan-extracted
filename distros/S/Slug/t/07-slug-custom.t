#!perl
use 5.008003;
use strict;
use warnings;
use utf8;
use Test::More tests => 12;
use Slug qw(slug_custom);

# Default options
is(slug_custom("Hello World"),
    "hello-world", "default options");

# Custom separator
is(slug_custom("Hello World", { separator => "_" }),
    "hello_world", "custom separator");

# No lowercase
is(slug_custom("Hello World", { lowercase => 0 }),
    "Hello-World", "lowercase disabled");

# No transliteration
is(slug_custom("Héllo", { transliterate => 0 }),
    "h-llo", "transliteration disabled");

# No trim
is(slug_custom(" Hello ", { trim_separator => 0 }),
    "-hello-", "trim disabled keeps leading and trailing sep");

# All options combined
is(slug_custom("Hello World", {
    separator      => ".",
    lowercase      => 0,
    max_length     => 10,
    transliterate  => 1,
    trim_separator => 1,
}), "Hello.Worl", "all options combined");

# Empty separator
is(slug_custom("Hello World", { separator => "" }),
    "helloworld", "empty separator");

# Multi-char separator
is(slug_custom("a b c", { separator => "--" }),
    "a--b--c", "multi-char separator");

# Transliterate off with unicode
is(slug_custom("Café", { transliterate => 0 }),
    "caf", "unicode dropped when transliterate disabled");

# Max length with trim
is(slug_custom("Hello World Test", { max_length => 13 }),
    "hello-world-t", "max_length cuts mid-word");

# Lowercase off with unicode
is(slug_custom("Café", { lowercase => 0 }),
    "Cafe", "uppercase transliteration preserved");

# Invalid second arg
eval { slug_custom("test", "not a hash") };
like($@, qr/hash reference/, "dies on non-hashref");
