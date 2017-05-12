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
    q{use Scalar::Util;},
    q{use Scalar::Util qw/weakening/;},
);
my @examples_yes=(
    q{use Scalar::Util qw/test weaken test/;},
    q{use Scalar::Util qw/weaken/;},
    q{use Scalar::Util qw/isweak/;},
    q{Scalar::Util::weaken($b);},
    q'if(Scalar::Util::isweak($a)) {}',
    q'if(Scalar::Util::isweak $a ) {}',
);
plan tests =>(@examples_yes+@examples_not);
foreach my $example (@examples_not) {
        my $p = Perl::MinimumVersion->new(\$example);
        is( $p->_weaken,'',$example );
}
foreach my $example (@examples_yes) {
        my $p = Perl::MinimumVersion->new(\$example);
        ok( $p->_weaken, $example );
}
