#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.47;

use Perl::MinimumVersion;
my @examples_not=(
    q'print "Internals::SvREADONLY"',
    q'defined &Internals::SvREADONLY',
);
my @examples_yes=(
    q'Internals::SvREADONLY($scalar, 1);',
    q'Internals::SvREADONLY(%hash, 1);',
);
plan tests =>(@examples_not+@examples_yes);
my $method='_internals_svreadonly';
foreach my $example (@examples_not) {
	my $p = Perl::MinimumVersion->new(\$example);
	is( $p->$method, '', $example )
	  or do { diag "\$\@: $@" if $@ };
}
foreach my $example (@examples_yes) {
	my $p = Perl::MinimumVersion->new(\$example);
	ok( $p->$method, "$example - detected")
	  or do { diag "\$\@: $@" if $@ };
}

