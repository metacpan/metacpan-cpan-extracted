#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Perl::MinimumVersion;

my %examples=(
    q{use experimental 'signatures'; } => '5.020',
    q{use experimental; } => '5.004',
);

plan tests => scalar keys %examples;

foreach my $example (sort keys %examples) {
    my $v = Perl::MinimumVersion->new(\$example)->minimum_version;
    is( $v, $examples{$example}, $example )
        or $@ && diag $@;
}
