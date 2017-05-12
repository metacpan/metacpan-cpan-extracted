#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 0.47;

use Perl::MinimumVersion;
my @examples_not=(
    q'exists $a{b}',
    q'exists($a{b})',
    q'exists $a{f(b)}',
    q'exists $ref->{A}->{B}',
    q'exists f->{A}->{B}',
    q'$obj->exists(&a)',
);
my @examples_yes=(
    q{exists &a},
    q{exists(&a)},
    q{exists &$a},
    #q{exists & $a}, #will implement someday
    q{exists(&$a)},
    q/exists &{$ref->{A}{B}{$key}}/,
);
plan tests =>(@examples_not+@examples_yes);
my $method='_exists_subr';
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

