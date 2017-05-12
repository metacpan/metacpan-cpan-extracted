#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.47;

#use version;
use Perl::MinimumVersion;

my %examples=(
    q{state $x;}                => '5.010',
    q{state @x;}                => '5.010',
    q{state($x,$y);}            => '5.010',
    q{%hash = (state => 3);}    => '5.004',
    q{print 'state $x;';}       => '5.004',
);

plan tests => scalar(keys %examples);
foreach my $example (sort keys %examples) {
	my $p = Perl::MinimumVersion->new(\$example);
    my $v = $p->minimum_version;
	is( $v, $examples{$example}, $example )
	  or do { diag "\$\@: $@" if $@ };
}
