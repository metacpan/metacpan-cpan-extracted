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
    q{A::B::C},
    q{A::B},
);
my @examples_yes=(
    q{A::B::},
    q{A::},
    q{new A::B::},
    q{new A::B:: $c},
);
plan tests =>(@examples_not+@examples_yes);
foreach my $example (@examples_not) {
	my $p = Perl::MinimumVersion->new(\$example);
	is( $p->_bareword_double_colon, '', $example )
	  or do { diag "\$\@: $@" if $@ };
}
foreach my $example (@examples_yes) {
	my $p = Perl::MinimumVersion->new(\$example);
	ok( $p->_bareword_double_colon, "$example - detected")
	  or do { diag "\$\@: $@" if $@ };
}

