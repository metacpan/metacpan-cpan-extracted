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
    q{substr 'asdf',1,1 or print 2,2;},
    q{substr('asdf',1,1);},
    q{my $a=substr('asdf',1,1);},
    q{$a->substr('asdf',1,1,'aa');},
);
my @examples_yes=(
    q{substr('asdf',1,1,'tt');},
    q{my $a=substr('asdf',1,1,'aa');},
    q/if(substr('asdf',1,1,'aa')) {}/,
);
plan tests =>(@examples_yes+@examples_not);
foreach my $example (@examples_not) {
        my $p = Perl::MinimumVersion->new(\$example);
        is($p->_substr_4_arg,'',$example);
}
foreach my $example (@examples_yes) {
        my $p = Perl::MinimumVersion->new(\$example);
        is($p->_substr_4_arg, 'substr', $example);
}
