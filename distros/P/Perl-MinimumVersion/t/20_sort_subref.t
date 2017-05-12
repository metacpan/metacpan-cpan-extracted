#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 0.47;

use Perl::MinimumVersion;
my @examples_not=(
    q'sort $coderef, @foo',
    q'sort $coderef , @foo',
    q'sort; $coderef, @foo',
    q'sort {$a} @foo',
    q'sort func $var',
);
my @examples_yes=(
    q'sort $coderef @foo',
    #q'sort $$coderef @foo', #later
    q'sort $coderef @$foo',
    q'sort $coderef (@foo, @l)',
    q'sort $coderef @{$foo}',
    q'sort $coderef f($foo)',
);
plan tests =>(@examples_not+@examples_yes);
my $method='_sort_subref';
foreach my $example (@examples_not) {
	my $p = Perl::MinimumVersion->new(\$example);
	is( $p->$method, '', "$example - not detected")
	  or do { diag "\$\@: $@" if $@ };
}
foreach my $example (@examples_yes) {
	my $p = Perl::MinimumVersion->new(\$example);
	ok( $p->$method, "$example - detected")
	  or do { diag "\$\@: $@" if $@ };
}

