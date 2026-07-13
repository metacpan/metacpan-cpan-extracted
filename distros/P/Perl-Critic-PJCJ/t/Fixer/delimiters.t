#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0 qw( done_testing subtest );

use lib             qw( lib t/lib );
use ViolationFinder qw( fixes unchanged );

subtest "qw() delimiters are optimised" => sub {
  fixes 'my @w = qw/one two/;', 'my @w = qw(one two);',
    "exotic qw delimiter becomes parentheses";
  fixes 'my @w = qw{word(with)parens};', 'my @w = qw[word(with)parens];',
    "unbalanced parens in content choose square brackets";
  fixes 'my @w = qw/a\/b/;', 'my @w = qw(a/b);',
    "escaped old delimiter is unescaped";
  fixes 'my @w = qw//;', 'my @w = qw();', "empty qw gets parentheses";
};

subtest "qx() delimiters are optimised" => sub {
  fixes 'my $out = qx/ls/;', 'my $out = qx(ls);',
    "exotic qx delimiter becomes parentheses";
};

subtest "q() and qq() delimiters are optimised" => sub {
  fixes q(my $x = q|has 'single' and "double"|;),
    q[my $x = q(has 'single' and "double");],
    "exotic q delimiter becomes parentheses";
  fixes 'my $x = qq/tab\there/;', 'my $x = qq(tab\there);',
    "exotic qq delimiter becomes parentheses";
};

subtest "Plain quotes move to operators when justified" => sub {
  fixes q(my $x = 'has \'single\' and "double"';),
    q[my $x = q(has 'single' and "double");],
    "single quotes with both quote types become q()";
  fixes 'my $x = "say \"$x\"";', 'my $x = qq(say "$x");',
    "escaped double quotes with interpolation become qq()";
  fixes 'my $x = "(\"$x\")";', 'my $x = qq[("$x")];',
    "parens in content choose square brackets for qq";
};

subtest "Optimal delimiters are untouched" => sub {
  unchanged 'my @w = qw(already good);', "optimal qw() stays";
  unchanged 'my $x = qq(tab\there);',    "optimal qq() stays";
  unchanged 'my $out = qx(ls -l);',      "optimal qx() stays";
};

done_testing
