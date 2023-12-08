#!/usr/bin/env perl

use strict;
use warnings;
use feature 'state';

use Sub::Genius;

my $NUM_THREADS = 6;

my $preplan = q{
(
  step  # step_id = 0
  &
  step  # step_id = 1
  &
  step
  &
  step
  &
  step
  &
  step  # step_id = 5
)
reduce
};

my $final_scope = Sub::Genius->new( preplan => $preplan )->run_any( scope => { sum => 0.0, num_steps => 1_000_000, pi => undef } );

printf qq{pi = %f\n}, $final_scope->{pi};

sub step {
    my $scope   = shift;
    state $step_id = 0;   # track and increment "step number" (or "thread id" via state)
    $scope->{sum} = _do_calc( $step_id, $scope );
    ++$step_id;
    return $scope;
}

sub reduce {
    my $scope     = shift;
    my $num_steps = $scope->{num_steps};
    my $step      = 1 / $num_steps;
    $scope->{pi} = $scope->{sum} * $step;
    return $scope;
}

sub _do_calc {
    my ( $id, $scope ) = @_;
    my $sum       = $scope->{sum};
    my $num_steps = $scope->{num_steps};
    my $step      = 1 / $num_steps;
    for ( my $i = $id ; $i < $num_steps ; $i += $NUM_THREADS ) {
        my $x = ( $i + 0.5 ) * $step;
        $sum += 4.0 / ( 1 + $x * $x );
    }
    return $sum;
}

