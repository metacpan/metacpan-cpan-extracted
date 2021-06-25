#!/usr/bin/env perl

use strict;
use warnings;
use feature 'state';

use Sub::Genius ();

# the plan is a PRE, 'parallel regular expression' in the Formal sense
my $preplan = q{
begin 
  ( step1 & step2 )
fin
};

# Load PRE describing concurrent semantics
my $sq = Sub::Genius->new( preplan => $preplan );

# treated as "shared memory"
my $GLOBAL = {};

# run plan
my $final_scope = $sq->run_any( scope => {}, );

# implement sub routines
sub begin {
  my $scope = shift;
  state $sub_state = {};
  # ..
  return $scope;
}

sub step1 {
  my $scope = shift;
  state $sub_state = {};
  # ...
  return $scope;
}

sub step2 {
  my $scope = shift;
  state $sub_state = {};
  # ...
  return $scope;
}

sub fin {
  my $scope = shift;
  state $sub_state = {};
  # ...
  return $scope;
}

exit;
