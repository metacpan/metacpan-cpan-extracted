#!perl
use 5.008003;
use strict;
use warnings;
use Test::More tests => 10;
use Slug qw(slug);

# Empty and whitespace
is(slug(""),                  "",                  "empty string");
is(slug("   "),               "",                  "only spaces");
is(slug("---"),               "",                  "only dashes");
is(slug("!!!@@@###"),         "",                  "only symbols");

# Single character
is(slug("a"),                 "a",                 "single letter");
is(slug("A"),                 "a",                 "single uppercase letter");
is(slug("1"),                 "1",                 "single digit");
is(slug("!"),                 "",                  "single symbol");

# Long input (stress test)
my $long = "hello " x 1000;
my $result = slug($long);
ok(length($result) > 0,       "long input produces output");
like($result, qr/^hello(-hello)*$/, "long input correct pattern");
