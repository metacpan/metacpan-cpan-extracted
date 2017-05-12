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
    q{mkdir1('test',1);},
    q{mkdir('test',1);},
    q{mkdir 'test',1;},
    q{$test->mkdir('a');},
);
my @examples_yes=(
    q{mkdir('test');},
    q{mkdir 'test';},
    q{$c=mkdir('test');},
);
plan tests =>(@examples_not+@examples_yes);
foreach my $example (@examples_not) {
        my $p = Perl::MinimumVersion->new(\$example);
        is( $p->_mkdir_1_arg, '', $example )
	or do { diag "\$\@: $@" if $@ };
}
foreach my $example (@examples_yes) {
        my $p = Perl::MinimumVersion->new(\$example);
        is( $p->_mkdir_1_arg, 'mkdir', $example )
	or do { diag "\$\@: $@" if $@ };
}
