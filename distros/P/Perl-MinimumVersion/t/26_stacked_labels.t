#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.47;

#use version;
use Perl::MinimumVersion;

my %examples=(
    q/ $x = 0;                          /   => '5.004',
    q/ LABEL1: $x = 0;                  /   => '5.004',
    # q/ LABEL1: LABEL2: $x = 0;          /   => '5.014',
    # q/ LABEL1:LABEL2: $x = 0;           /   => '5.014',
    q/ LABEL1: $x = 0; LABEL2: $y = 0;  /   => '5.004',
);

plan tests => scalar(keys %examples);
foreach my $example (sort keys %examples) {
	my $p = Perl::MinimumVersion->new(\$example);
    my $v = $p->minimum_version;
	is( $v, $examples{$example}, $example )
	  or do { diag "\$\@: $@" if $@ };
}
