#!/usr/bin/env perl
use strict;
use warnings;
use feature 'state';
use Test::More;

use_ok q{Sub::Genius};

my $preplan = q{
  init
  ( 
    subA
    (
      subB
      _DO_LAZY_SEQ_   #<~ this subroutine encapsulates another PRE
      subC
    )
    &
    subD
    &
    subB
  )
  fin
};

## intialize hash ref as container for global memory
my $GLOBAL = {};

## initialize Sub::Genius (caching 'on' by default)
my $sq = Sub::Genius->new( preplan => qq{$preplan} );

isa_ok $sq, q{Sub::Genius};

$sq->init_plan;
my $final_scope = $sq->run_once( scope => {} );

my $expected = {
    fin          => q{I'll be boch!!},
    fin_count    => 1,
    canary       => q{Squawwwk!!! Coal mine be dangerous!},
    canary_count => 1,
    subA_count   => 1,
    subB         => q{There be pirates!},
    subC_count   => 1,
    init_count   => 1,
};

# $scope built up in cooperation with top level PRE and contribution
# from the lazily linearized PRE via _DO_LAZY_SEQ_
is_deeply $final_scope, $expected, q{Final scope is as expected};

done_testing();

#
# S U B R O U T I N E S
#

sub subC {
    my $scope = shift;      # execution context passed by Sub::Genius::run_once
    state $mystate = {};    # sticks around on subsequent calls
    my $myprivs = {};       # reaped when execution is out of sub scope

    ++$scope->{subC_count};

    # return $scope, which will be passed to next subroutine
    return $scope;
}

# nested linearization
sub _DO_LAZY_SEQ_ {
    my $scope = shift;      # execution context passed by Sub::Genius::run_once

    my $inner_preplan = q{
     ( lazy_canary subB )  #<~ for testing, constrain total ordering
              &
            subD
   };

    my $expected = {
        init_count   => 1,
        canary       => q{Squawwwk!!! Coal mine be dangerous!},
        canary_count => 1,
        subB         => q{There be pirates!},
        subA_count   => 1,
    };

    my $sq2 = Sub::Genius->new( preplan => $inner_preplan );
    isa_ok $sq2, q{Sub::Genius};

    # starts off with $scope, initialized from above
    my $final_inner_scope = $sq2->run_any( scope => $scope );

    is_deeply $final_inner_scope, $expected, q{lazily evaluated inner scope is as expected};

    # return $scope, which will be passed to next subroutine
    return $scope;
}

sub lazy_canary {
    my $scope = shift;      # execution context passed by Sub::Genius::run_once
    state $mystate = {};    # sticks around on subsequent calls
    my $myprivs = {};       # reaped when execution is out of sub scope

    ++$scope->{canary_count};
    $scope->{canary} = q{Squawwwk!!! Coal mine be dangerous!};

    # return $scope, which will be passed to next subroutine
    return $scope;
}

sub subA {
    my $scope = shift;      # execution context passed by Sub::Genius::run_once
    state $mystate = {};    # sticks around on subsequent calls
    my $myprivs = {};       # reaped when execution is out of sub scope

    ++$scope->{subA_count};

    # return $scope, which will be passed to next subroutine
    return $scope;
}

sub fin {
    my $scope = shift;      # execution context passed by Sub::Genius::run_once
    state $mystate = {};    # sticks around on subsequent calls
    my $myprivs = {};       # reaped when execution is out of sub scope

    ++$scope->{fin_count};
    $scope->{fin} = q{I'll be boch!!};

    # return $scope, which will be passed to next subroutine
    return $scope;
}

sub init {
    my $scope = shift;      # execution context passed by Sub::Genius::run_once
    state $mystate = {};    # sticks around on subsequent calls
    my $myprivs = {};       # reaped when execution is out of sub scope

    ++$scope->{init_count};

    # return $scope, which will be passed to next subroutine
    return $scope;
}

sub subB {
    my $scope = shift;      # execution context passed by Sub::Genius::run_once
    state $mystate = {};    # sticks around on subsequent calls
    my $myprivs = {};       # reaped when execution is out of sub scope

    # update $scope prior to lazily linearized PRE
    $scope->{subB} = q{There be pirates!};

    # return $scope, which will be passed to next subroutine
    return $scope;
}

sub subD {
    my $scope = shift;      # execution context passed by Sub::Genius::run_once
    state $mystate = {};    # sticks around on subsequent calls
    my $myprivs = {};       # reaped when execution is out of sub scope

    # return $scope, which will be passed to next subroutine
    return $scope;
}

exit;
__END__
