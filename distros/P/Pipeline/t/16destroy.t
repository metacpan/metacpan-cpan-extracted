#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Pipeline;
use Pipeline::Segment::Tester;
use Scalar::Util  qw( weaken );
use Data::Dumper;

our $UTIL;
BEGIN {
  eval q{ use Data::Structure::Util qw( has_circular_ref ) };
  if ($@) {
    warn "Data::Structure::Util not installed, skip tests\n";
    eval qq{ use Test::Simple tests => 2 };
  }
  else {
    $UTIL = 1;
    eval qq{ use Test::Simple tests => 3 };
  }
  warn $@ if $@;
}


my $weak;
{
  my $pipeline = Pipeline->new();
  $pipeline->add_segment( Pipeline::Segment::Tester->new() );
  $pipeline->add_segment( Pipeline::Segment::Tester->new() );
  $pipeline->cleanups->add_segment(Pipeline::Segment::Tester->new());
  $pipeline->dispatch;
  
  if ($UTIL) {
    ok(! has_circular_ref($pipeline), "No circular ref detected");
  }
  
  $weak = $pipeline;
  weaken($weak);
  ok(ref($weak) eq 'Pipeline', "Got a weak reference to pipeline");
}

ok(! $weak, "Pipeline has been destroyed");
