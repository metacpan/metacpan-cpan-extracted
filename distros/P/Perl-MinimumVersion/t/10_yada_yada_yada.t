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
    q{'foo'.'foo'}, # okay, okay, adding close examples is a TODO
    q/sub foo {}/,
    q{1 ... 3}, #sed version of flip-flop
    q[grep { /^$newver(?:\s+|$)/ ... /^\S/ }], #RT#59774
);
my @examples_yes=(
    q{...},
    q{ ... },
    q{...;},
    q/if(1){...}/,
    q/sub foo {...}/,
);
plan tests =>(@examples_not+@examples_yes);
foreach my $example (@examples_not) {
	my $p = Perl::MinimumVersion->new(\$example);
	is( $p->_yada_yada_yada, '', $example )
	  or do { diag "\$\@: $@" if $@ };
}
foreach my $example (@examples_yes) {
	my $p = Perl::MinimumVersion->new(\$example);
	ok( $p->_yada_yada_yada, $example )
	  or do { diag "\$\@: $@" if $@ };
}

