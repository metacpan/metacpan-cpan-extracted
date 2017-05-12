#!/usr/bin/perl

use strict;
use warnings;
use Error qw( :try );
use Test::More no_plan => 1;

use_ok(class());
ok( error() );

sub error {
  try {
    Pipeline::Segment::Failure->new();
  } catch Pipeline::Error::Construction with {
    return 1;
  } finally {
    return 0;
  };
}

sub class { "Pipeline::Base" }

package Pipeline::Segment::Failure;

use Pipeline::Segment;
use base qw( Pipeline::Segment );

sub init { 0; }
