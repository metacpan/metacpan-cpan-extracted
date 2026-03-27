#!perl
use 5.008003;
use strict;
use warnings;
use Test::More tests => 10;
use Slug qw(slug);

# Custom separator
is(slug("Hello World", "_"),    "hello_world",       "underscore separator");
is(slug("Hello World", "."),    "hello.world",       "dot separator");
is(slug("Hello World", "~"),    "hello~world",       "tilde separator");
is(slug("Hello World", ""),     "helloworld",        "empty separator");
is(slug("Hello World", "--"),   "hello--world",      "multi-char separator");
is(slug("Hello World", "___"), "hello___world",     "triple underscore separator");

# Separator with special chars in input
is(slug("a  b  c", "_"),       "a_b_c",             "multiple spaces with underscore");
is(slug("a--b--c", "_"),       "a_b_c",             "dashes with underscore separator");
is(slug(" Hello ", "_"),        "hello",             "trimmed with underscore");
is(slug("Hello---World", "."), "hello.world",       "dashes collapsed with dot sep");
