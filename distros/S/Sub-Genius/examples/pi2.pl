#!/usr/bin/env perl

use strict;
use warnings;

use Sub::Genius;

my $NUM_THREADS = 6;

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

sub AUTOLOAD {
    our $AUTOLOAD;
    my $sub = $AUTOLOAD;
    $sub =~ s/.*:://;
    die if $sub !~ m/^step([\d]+)/;
    my $step_id = $1;

    # deal with 'step'
    my $old_scope = shift;
    my $new_scope = _snep( $step_id, $old_scope );
    return $new_scope;
}

sub _snep {
    my ( $step_id, $scope ) = @_;
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

