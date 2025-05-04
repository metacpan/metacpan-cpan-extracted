#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Perl::MinimumVersion;

my %examples=(
    q{
    my $var = <<~HEREDOC;
    My text.
    HEREDOC
    } => '5.025007',

    q{
    my $var = <<HEREDOC;
My text.
HEREDOC
    } => '5.006',
);

plan tests => scalar keys %examples;

foreach my $example (sort keys %examples) {
    my $v = Perl::MinimumVersion->new(\$example)->minimum_version;
    is( $v, $examples{$example}, $example )
        or $@ && diag $@;
}
