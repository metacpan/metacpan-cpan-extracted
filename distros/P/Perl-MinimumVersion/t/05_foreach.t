#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 0.47;

#use version;
use Perl::MinimumVersion;
my @examples_not=(
    q'foreach (1,2,3) {}',
    q{print "$_," while $a;},
);
my @examples_yes=(
    q{print "$_," foreach split //,"asdf";},
    q{print "$_," foreach (1,2,3,4);},
    q{print "$_," foreach 'asdf';},
);
plan tests =>(@examples_yes+@examples_not);
foreach my $example (@examples_not) {
        my $p = Perl::MinimumVersion->new(\$example);
        is($p->_postfix_foreach, '', $example);
}
foreach my $example (@examples_yes) {
        my $p = Perl::MinimumVersion->new(\$example);
        is($p->_postfix_foreach, 'foreach', $example);
}
