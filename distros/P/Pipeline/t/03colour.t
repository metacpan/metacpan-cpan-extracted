#!/usr/bin/perl -w
use strict;

BEGIN {
  eval {
    require Acme::Colour;
  };
  if ($@) {
    print "1..0 # Skipped - do not have Acme::Colour installed\n";
    exit;
  }
}

use lib './lib';
#use lib 'oldt/lib';
use lib 't/lib';
use Dye;
use Tap;
use Water;
use Pipeline;
use Test::More tests => 6;

# Check that water can change colour

my $water = Water->new();
isa_ok($water, 'Water', "should get water object");
is($water->colour, 'clear', "water should be clear");
$water->dye("blue");
is($water->colour, 'light slate blue', "water should be light slate blue");

# Create a water pipeline with red and blue dyes

my $pipeline = Pipeline->new();
#$pipeline->debug( 1 );
$pipeline->add_segment(
  Tap->new(type => 'in'  ),
  Dye->new( ink => 'red' ),
  Dye->new( ink => 'blue'),
  Tap->new(type => 'out' ),
);
ok($pipeline, "we have a pipeline");
my $production = $pipeline->dispatch();
isa_ok($production, 'Water', "should get water out of the pipe");
is($production->colour, 'dark magenta', "should get dark magenta water out");

