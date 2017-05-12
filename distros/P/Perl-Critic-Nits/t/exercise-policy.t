#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Perl::Critic::TestUtils qw/subtests_in_tree pcritique/;

my $policy = 'ValuesAndExpressions::ProhibitAccessOfPrivateData';

my $subtests = subtests_in_tree( 't/ValuesAndExpressions' );

my $test_count = 0;

$test_count += @{ $subtests->{ $_ } } for keys %{ $subtests };

plan tests => $test_count;

for my $policy( sort keys %{ $subtests } ){
  for my $subtest( @{ $subtests->{ $policy } } ){
    local $TODO = $subtest->{ TODO };

    my $desc = "$subtest->{ name } (line $subtest->{ lineno })";

    my $violations = $subtest->{ filename }
      ? eval {
        fcritique( $policy, \$subtest->{ code }, $subtest->{ filename },
          $subtest->{ parms } );
      }
      : eval { pcritique( $policy, \$subtest->{ code }, $subtest->{ parms } ) };

      my $err = $@;

      if( $subtest->{ error } ){
        if( 'Regexp' eq ref $subtest->{ error } ){
          like( $err, $subtest->{ error }, $desc );
        }
        else {
          ok( $err, $desc );
        }
      }
      else {
        die $err if $err;
        is( $violations, $subtest->{ failures }, $desc );
      }
  }
}
