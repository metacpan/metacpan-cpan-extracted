#!/usr/bin/perl

use DataFlow;

my $flow =
  DataFlow->new(
    procs => [ [ Encoding => { from => 'iso-8859-1', to => 'utf8' } ] ] );

map {
    printf '%03d(%02x): %3s %3s' . "\n", $_, $_, chr($_),
      $flow->process( chr($_) )
} 0 .. 255;
