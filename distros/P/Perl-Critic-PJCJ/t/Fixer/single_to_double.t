#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0 qw( done_testing subtest );

use lib             qw( lib t/lib );
use ViolationFinder qw( fixes unchanged );

subtest "Simple single-quoted strings become double-quoted" => sub {
  fixes q(my $x = 'hello';), 'my $x = "hello";', "simple string is re-quoted";
  fixes q(my $x = 'hello world';), 'my $x = "hello world";',
    "string with spaces is re-quoted";
  fixes q(say 'ready' if $ok;), 'say "ready" if $ok;',
    "string in larger statement is re-quoted";
};

subtest "Escapes are re-encoded, not copied" => sub {
  fixes q(my $x = 'I\'m happy';), q(my $x = "I'm happy";),
    "escaped single quote becomes plain";
  fixes q(my $x = 'a\ b';), 'my $x = "a\\\\ b";',
    "literal backslash is escaped for double quotes";
};

subtest "Multiple strings are all fixed" => sub {
  fixes q[my ($a, $b) = ('one', 'two');], 'my ($a, $b) = ("one", "two");',
    "both strings on one line are re-quoted";
};

subtest "Strings the policy accepts are untouched" => sub {
  unchanged q(my $x = 'user@domain.com';), 'literal @ stays single-quoted';
  unchanged q(my $x = 'literal$var';),     'literal $ stays single-quoted';
  unchanged q(my $x = 'He said "hello"';), "embedded double quotes stay";
  unchanged q(my $x = 'tab\there';),       "quote-sensitive escape stays";
  unchanged qq(my \$x = 'line1\nline2';),  "string with newline stays";
  unchanged 'my $x = "already double";',   "double-quoted string stays";
  unchanged 'my $n = 42;',                 "code without strings stays";
};

subtest "Surrounding source is preserved exactly" => sub {
  fixes qq(my \$x   = 'spaced';  # comment\nmy \$y = 1;\n),
    qq(my \$x   = "spaced";  # comment\nmy \$y = 1;\n),
    "whitespace and comments are untouched";
};

done_testing
