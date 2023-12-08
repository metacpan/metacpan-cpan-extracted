#!/usr/bin/env perl
use strict;
use warnings;
use feature 'state';

use Sub::Genius ();

my $preplan = q{
 init
 ( subA
     &
     (
       subB
       _DO_LAZY_SEQ_   #<~ this subroutine encapsulates another PRE
       subC
     )
     &
   subD
 )
 fin
};

## intialize hash ref as container for global memory
my $GLOBAL = {};


## initialize Sub::Genius (caching 'on' by default)
my $sq = Sub::Genius->new(preplan => qq{$preplan} );
$sq->init_plan;
my $final_scope = $sq->run_once( scope => {}, ns => q{main}, verbose => 1);


#
# S U B R O U T I N E S
#

#TODO - implement the logic!
sub init {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub init: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub subA {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub subA: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub subB {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub subB: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub _DO_LAZY_SEQ_ {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub _DO_LAZY_SEQ_: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub this {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub this: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub subroutine {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub subroutine: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub encapsulates {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub encapsulates: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub another {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub another: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub PRE {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub PRE: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub subC {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub subC: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub subD {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub subD: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub  {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub : ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub fin {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub fin: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub subA {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub subA: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub another {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub another: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub init {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub init: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub subC {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub subC: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub encapsulates {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub encapsulates: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub _DO_LAZY_SEQ_ {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub _DO_LAZY_SEQ_: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub subB {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub subB: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub subD {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub subD: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub this {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub this: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub fin {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub fin: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub subroutine {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub subroutine: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

#TODO - implement the logic!
sub PRE {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope

  #-- begin subroutine implementation here --#
  print qq{Sub PRE: ELOH! Replace me, I am just placeholder!\n};

  # return $scope, which will be passed to next subroutine
  return $scope;
}

exit;
__END__

=head1 NAME

nameMe - something click bait worthy for CPAN

=head1 SYNAPSIS

..pithy example of use

=head1 DESCRIPTION

..extended wordings on what this thing does

=head1 METHODS

=over 4

=item * C<subA>

=item * C<another>

=item * C<init>

=item * C<subC>

=item * C<encapsulates>

=item * C<_DO_LAZY_SEQ_>

=item * C<subB>

=item * C<subD>

=item * C<this>

=item * C<fin>

=item * C<subroutine>

=item * C<PRE>

=back

=head1 SEE ALSO

L<Sub::Genius>, L<FLAT>

=head1 COPYRIGHT AND LICENSE

Same terms as perl itself.

=head1 AUTHOR

Rosie Tay Robert E<lt>rtr@example.tldE<gt>
