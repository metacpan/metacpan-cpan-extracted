#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.47;

use Perl::MinimumVersion;
my @examples_not=(
    q'while(my $f=readdir $dh) {}',
    q'while("readdir") {}',
    q'while {readdir}',
    q'while(readdir $dh gt "test") {}',
    q'while(readdir($dh) gt "test") {}',
);
my @examples_yes=(
    q'while(readdir $dh) {}',
    q'while(readdir($dh)) {}',
    q'say while(readdir $dh);',
    #q'say while readdir $dh;', - ToDo
);
plan tests =>(@examples_not+@examples_yes);
my $method='_while_readdir';
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

