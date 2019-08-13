#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Perl::Critic::TestUtils qw[ subtests_in_tree pcritique ];

my $setup_ref = subtests_in_tree('t');
plan tests => scalar keys %$setup_ref;

foreach my $policy (keys %$setup_ref) {
    my $cases_ref = $setup_ref->{$policy};
    subtest $policy => sub {
        plan tests => scalar @$cases_ref;
        foreach my $case_ref (@$cases_ref) {
            my ($code, $exp_failures) = @$case_ref{qw[ code failures ]};
            my $name = "$case_ref->{name} (exp. failures = $exp_failures)";
            my $violations = pcritique($policy, \$code, $case_ref->{parms});
            cmp_ok $violations, '==', $exp_failures, $name or diag $code;
        }
    };
}
