#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0 qw( done_testing subtest );

use lib             qw( lib t/lib );
use ViolationFinder qw( fixes unchanged );

subtest "Escaped sigils become literal in single quotes" => sub {
  fixes 'my $x = "user\@domain.com";', q(my $x = 'user@domain.com';),
    'escaped @ becomes literal';
  fixes 'my $x = "literal\$var";', q(my $x = 'literal$var';),
    'escaped $ becomes literal';
  fixes 'my $x = "\$5.00";', q(my $x = '$5.00';),
    'leading escaped $ becomes literal';
};

subtest "Escaped double quotes become literal" => sub {
  fixes 'my $x = "He said \"hello\"";', q(my $x = 'He said "hello"';),
    "escaped double quotes become literal";
};

subtest "Apostrophe content becomes q() to avoid escaping" => sub {
  fixes q(my $x = "\$10 isn't";), q[my $x = q($10 isn't);],
    "escaped sigil with an apostrophe becomes q() not single quotes";
};

subtest "Backslashes are re-encoded" => sub {
  fixes 'my $x = "price \$x\\\\y";', q(my $x = 'price $x\\\\y';),
    "escaped backslash stays escaped in single quotes";
};

subtest "Double-quoted strings the policy accepts are untouched" => sub {
  unchanged 'my $x = "Hello $name";', "interpolating string stays";
  unchanged 'my $x = "tab\there";',   "quote-sensitive escape stays";
  unchanged 'my $x = "simple";',      "simple double-quoted string stays";
  unchanged q(my $x = "don\'t";),     "escaped single quote is not flagged";
};

done_testing
