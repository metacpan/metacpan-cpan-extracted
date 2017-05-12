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
    q{package Foo;},
    q{package Foo;},
    q{use Foo 1.2;},
    q{package Foo::Bar;},
);
my @examples_yes=(
    q{package Foo 1;},
    q{package Foo::Bar 1;},
    q{package Foo 1;},
    q{package Foo 1.;},
    q{package Foo::Bar::Baz 1.000},
    q{package Foo::Bar::Baz 1.1.1},
);
plan tests =>(@examples_not+@examples_yes);
foreach my $example (@examples_not) {
	my $p = Perl::MinimumVersion->new(\$example);
	is( $p->_pkg_name_version, '', $example )
	  or do { diag "\$\@: $@" if $@ };
}
foreach my $example (@examples_yes) {
	my $p = Perl::MinimumVersion->new(\$example);
	ok( $p->_pkg_name_version, $example )
	  or do { diag "\$\@: $@" if $@ };
}

