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
    qw{ < > <> },
);
my @examples_yes=(
    qw{ <<>> },
);
plan tests =>(@examples_not+@examples_yes);
foreach my $example (@examples_not) {
	my $p = Perl::MinimumVersion->new(\$example);
	is( $p->_double_diamond_operator, '', $example )
	  or do { diag "\$\@: $@" if $@ };
}
foreach my $example (@examples_yes) {
	my $p = Perl::MinimumVersion->new(\$example);
	ok( $p->_double_diamond_operator, $example )
	  or do { diag "\$\@: $@" if $@ };
}

