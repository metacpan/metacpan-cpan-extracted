#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;

use_ok(
  'Perl::Critic::Policy::ValuesAndExpressions::ProhibitAccessOfPrivateData'
);

my $policy
  = Perl::Critic::Policy::ValuesAndExpressions::ProhibitAccessOfPrivateData
    ->new();

is( $policy->get_severity(), 5, 'high severity set' );

is_deeply(
  [ $policy->get_themes() ], [ qw/maintenance nits/ ], 'proper theme(s) set'
);

is_deeply (
  [ $policy->applies_to() ], [ qw/PPI::Token::Symbol/ ], 'applies only to words'
);

