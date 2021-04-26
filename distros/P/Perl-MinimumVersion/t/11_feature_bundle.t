#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.47;

#use version;
use Perl::MinimumVersion;
my %examples=(
    q{use feature ':5.8'} => '5.8.0',
    q{use feature} => undef,
    q{use feature 'say', ':5.10';} => '5.10.0',
    q{use feature ':5.10';use feature ':5.12';} => '5.12.0',
    q{use feature ':5.14';use feature ':5.12';} => '5.14.0',
    q{use feature 'state';} => '5.10.0',
    q{use feature 'switch';} => '5.10.0',
    q{use feature 'say';} => '5.10.0',
    q{use feature 'smartmatch';} => '5.10.0',
    q{use feature 'unicode_strings';} => '5.14.0',
    q{use feature 'unicode_eval';} => '5.16.0',
    q{use feature 'evalbytes';} => '5.16.0',
    q{use feature 'current_sub';} => '5.16.0',
    q{use feature 'array_base';} => '5.16.0',
    q{use feature 'fc';} => '5.16.0',
    q{use feature 'lexical_subs';} => '5.18.0',
    q{use feature 'postderef';} => '5.20.0',
    q{use feature 'postderef_qq';} => '5.20.0',
    q{use feature 'signatures';} => '5.20.0',
    q{use feature 'refaliasing';} => '5.22.0',
    q{use feature 'bitwise';} => '5.22.0',
    q{use feature 'declared_refs';} => '5.26.0',
    q{use feature 'isa';} => '5.32.0',
    q{use feature 'indirect';} => '5.32.0',
);
plan tests => scalar(keys %examples);
foreach my $example (sort keys %examples) {
	my $p = Perl::MinimumVersion->new(\$example);
	my ($v, $obj) = $p->_feature_bundle;
	is( $v, $examples{$example}, $example )
	  or do { diag "\$\@: $@" if $@ };
}
