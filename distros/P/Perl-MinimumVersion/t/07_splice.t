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
    q{splice(@a,1);},
    q{splice @a,1;},
    q{splice @a,1,1;},
    q{splice @a,1,1,@b;},
    q{splice @a,1 or die -1,1;},
    q{$test->splice(@a,1,-1,@b);},
);
my @examples_yes=(
    q{splice @a,1,-1;},
    q{splice(@a,1,-1);},
    q{$c=splice(@a,1,-1);},
);
plan tests =>(@examples_not+@examples_yes);
foreach my $example (@examples_not) {
        my $p = Perl::MinimumVersion->new(\$example);
        is($p->_splice_negative_length, '', $example)
	or do { diag "\$\@: $@" if $@ };
}
foreach my $example (@examples_yes) {
        my $p = Perl::MinimumVersion->new(\$example);
        is( $p->_splice_negative_length, 'splice', $example )
	or do { diag "\$\@: $@" if $@ };
}
