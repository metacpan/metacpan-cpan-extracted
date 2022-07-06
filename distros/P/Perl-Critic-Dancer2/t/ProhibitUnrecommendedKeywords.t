#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;
use File::Slurp qw/slurp/;
use Perl::Critic::TestUtils qw/pcritique/;
use lib '../lib';
 
my @tests = (
    [without_Dancer2      => 0],
    [with_Dancer2         => 1],
);

my $this_policy = 'Dancer2::ProhibitUnrecommendedKeywords';
 
foreach my $test (@tests) {
   my ( $package, $expected_violations ) = @$test;
   my $code       = slurp("t/lib/$package.pm");
   my $violations = pcritique( $this_policy, \$code );
   ok(
      ( $violations == $expected_violations ),
      "$package returned $expected_violations violations",
   ) or diag("--->Got $violations violations!");
}
 
done_testing;