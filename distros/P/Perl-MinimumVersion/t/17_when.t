#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 0.47;

use Perl::MinimumVersion;
my @examples_not=(
    q'when (1) {}',
    q'when ([1,2,3]) {}',
);
my @examples_yes=(
    q{print "$_," when [1,2,3];},
    q{print "$_," when([1,2,3]);},
    q{print "$_," when 1},
);
plan tests =>(@examples_not+@examples_yes);
foreach my $example (@examples_not) {
	my $p = Perl::MinimumVersion->new(\$example);
	is( $p->_postfix_when, '', $example )
	  or do { diag "\$\@: $@" if $@ };
}
foreach my $example (@examples_yes) {
	my $p = Perl::MinimumVersion->new(\$example);
	ok( $p->_postfix_when, "$example - detected")
	  or do { diag "\$\@: $@" if $@ };
}

