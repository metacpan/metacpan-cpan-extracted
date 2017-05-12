#!/usr/bin/perl

use strict;

use Pipeline;
use Pipeline::Segment;
use Test::Simple tests => 9;

my $pipeline = Pipeline->new();
my $second   = Pipeline->new();
#my $segment  = Pipeline::Segment->new();
my $final    = mySegment->new();
my $real     = myFinalSegment->new();
my $double   = myDoubleSegment->new();

ok( $pipeline, "created a pipeline");
#ok( $segment,  "created a default segment");
ok( $final,    "created production segment");
ok( $real,     "created final segment");
ok( $double,   "created double segment");
ok( $second,   "created second pipeline");

$pipeline->add_segment( $final, $real );

ok( @{$pipeline->segments()} == 2, "correct # of segments in pipeline");

my $num = $pipeline->dispatch();

ok( $num == 10, "production returned was correct");

$pipeline->segments( [] ); ## clear the pipeline

ok(@{$pipeline->segments()} == 0, "pipeline has been cleared");

$pipeline->add_segment( $second );
$second->add_segment( $double );

ok( $pipeline->dispatch()->isa( 'Pipeline::Production' ), "dispatch returned production that was 20");


package mySegment;

use strict;
use Pipeline::Segment;
use Pipeline::Production;

use base qw( Pipeline::Segment );

sub dispatch {
  my $self = shift;
  my $pipe = shift;
  return Pipeline::Production->new()->contents( 10 );
}

package myFinalSegment;

use strict;
use Pipeline::Segment;
use Pipeline::Production;

use base qw( Pipeline::Segment );

sub dispatch {
  my $self = shift;
  my $pipe = shift;
  return Pipeline::Production->new()->contents( 5 );
}

package myDoubleSegment;

use strict;
use Pipeline::Segment;
use Pipeline::Production;

use base qw( Pipeline::Segment );

sub dispatch {
  my $self = shift;
  my $pipe = shift;

  my $prod = Pipeline::Production->new();
  $prod->contents( $prod );

#  return Pipeline::Production->new()->contents( Pipeline::Production->new()->contents( 20 ) );
  $prod;
}

1;
