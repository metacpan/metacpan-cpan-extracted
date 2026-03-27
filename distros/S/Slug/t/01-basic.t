#!perl
use 5.008003;
use strict;
use warnings;
use Test::More tests => 20;
use Slug qw(slug);

# Basic ASCII slugification
is(slug("Hello World"),       "hello-world",       "basic two words");
is(slug("hello world"),       "hello-world",       "already lowercase");
is(slug("HELLO WORLD"),       "hello-world",       "uppercase input");
is(slug("Hello  World"),      "hello-world",       "double space collapsed");
is(slug("Hello   World"),     "hello-world",       "triple space collapsed");

# Punctuation
is(slug("Hello, World!"),     "hello-world",       "comma and exclamation");
is(slug("Hello - World"),     "hello-world",       "dash with spaces");
is(slug("Hello--World"),      "hello-world",       "double dash collapsed");
is(slug("foo.bar.baz"),       "foo-bar-baz",       "dots become separator");
is(slug("foo_bar_baz"),       "foo-bar-baz",       "underscores become separator");

# Trim
is(slug("  Hello World  "),   "hello-world",       "leading/trailing spaces trimmed");
is(slug("--Hello World--"),   "hello-world",       "leading/trailing dashes trimmed");
is(slug("!!!Hello!!!"),       "hello",             "leading/trailing symbols trimmed");

# Numbers
is(slug("Hello 123 World"),   "hello-123-world",   "numbers preserved");
is(slug("123"),               "123",               "numbers only");
is(slug("foo42bar"),          "foo42bar",           "numbers inline");

# Mixed
is(slug("Hello & World"),     "hello-world",       "ampersand stripped");
is(slug('foo@bar.com'),       "foo-bar-com",       "email-like input");
is(slug("a/b/c"),             "a-b-c",             "slashes");
is(slug("CamelCase"),         "camelcase",          "camelcase lowered");
