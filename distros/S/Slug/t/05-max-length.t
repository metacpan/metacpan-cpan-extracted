#!perl
use 5.008003;
use strict;
use warnings;
use Test::More tests => 8;
use Slug qw(slug_custom);

# max_length truncation
is(slug_custom("Hello Beautiful World", { max_length => 5 }),
    "hello",  "truncated to 5 chars");

is(slug_custom("Hello Beautiful World", { max_length => 11 }),
    "hello-beaut", "truncated to 11 chars");

is(slug_custom("Hello Beautiful World", { max_length => 100 }),
    "hello-beautiful-world", "max_length larger than output");

is(slug_custom("Hello World", { max_length => 0 }),
    "hello-world", "max_length 0 means unlimited");

# max_length with separator
is(slug_custom("Hello World", { max_length => 6, separator => "_" }),
    "hello_", "max_length mid-separator");

# max_length = 1
is(slug_custom("Hello", { max_length => 1 }),
    "h", "max_length 1");

# max_length with unicode
is(slug_custom("Caf\x{e9}", { max_length => 4 }),
    "cafe",  "max_length with unicode transliteration");

# max_length = exact
is(slug_custom("ab cd", { max_length => 5 }),
    "ab-cd", "max_length exact match");
