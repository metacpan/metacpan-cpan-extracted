package Defs::Defs;
use strict;
use warnings;

my $defs = {
  main => { proc => "pkg::MainProc", model => "pkg::Model", },

  #   comp_id2 =>
  #   {
  #    proc=>'MainProc',
  #    model=>['Model01','Model02','Model03'],
  #    map_filter=>'FilterProc'    # or ['Filter01','Filter02']
  #    reduce_filter=>'ReduceProc'  # reduce filter can apply at once.
  #    scalar_filter=>'ScalarProc'  # or ['Filter01','Filter02']
  #   }

  resource => {
    proc  => "Su::Procs::ResourceProc",
    model => "pkg::Model",
  },

};

sub defs {
  shift if ( $_[0] eq __PACKAGE__ );

  my $arg = shift;
  if ($arg) {
    $defs = $arg;
  } else {
    return $defs;
  }
} ## end sub defs
