#!/usr/bin/env perl

use strict;
use warnings;

use Sub::Genius;

my $NUM_THREADS = 5;

my $preplan = q{
(
  step0
  &
  step1
  &
  step2
  &
  step3
  &
  step4
  &
  step5
)
reduce
};

my $final_scope = Sub::Genius->new( preplan => $preplan )->run_any( scope => { sum => 0.0, num_steps => 1_000_000, pi => undef } );

printf qq{pi = %f\n}, $final_scope->{pi};

sub step0 {
    my $scope   = shift;
    my $step_id = 0;
    $scope->{sum} = _do_calc( $step_id, $scope );
    return $scope;
}

sub step1 {
    my $scope   = shift;
    my $step_id = 1;
    $scope->{sum} = _do_calc( $step_id, $scope );
    return $scope;
}

sub step2 {
    my $scope   = shift;
    my $step_id = 2;
    $scope->{sum} = _do_calc( $step_id, $scope );
    return $scope;
}

sub step3 {
    my $scope   = shift;
    my $step_id = 3;
    $scope->{sum} = _do_calc( $step_id, $scope );
    return $scope;
}

sub step4 {
    my $scope   = shift;
    my $step_id = 4;
    $scope->{sum} = _do_calc( $step_id, $scope );
    return $scope;
}

sub step5 {
    my $scope   = shift;
    my $step_id = 5;
    $scope->{sum} = _do_calc( $step_id, $scope );
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

