#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.47;

#use version;
use Perl::MinimumVersion;

my %examples=(
    q/ BEGIN { } /              => '5.004',
    q/ INIT { }  /              => '5.006',
    q/ CHECK { }  /             => '5.006002',
    q/ UNITCHECK { }  /         => '5.010',
);

plan tests => scalar(keys %examples);
foreach my $example (sort keys %examples) {
	my $p = Perl::MinimumVersion->new(\$example);
    my $v = $p->minimum_version;
	ok( $v == $examples{$example}, $example )
	  or do { diag "\$\@: $@" if $@ };
}
