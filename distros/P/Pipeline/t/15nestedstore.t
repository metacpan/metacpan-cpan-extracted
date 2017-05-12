#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Pipeline;

my $pipe1 = Pipeline->new();
my $pipe2 = Pipeline->new();

$pipe2->add_segment( MySegmentFetcher->new() );
$pipe1->add_segment( MySegmentPlacer->new(), $pipe2 );
$pipe1->dispatch();

package MySegmentPlacer;

use base qw( Pipeline::Segment );

sub dispatch {
  my $self = shift;
  $self->store->set(bless({},'Thing'));
}

package MySegmentFetcher;

use base qw( Pipeline::Segment );

sub dispatch {
  my $self = shift;
  main::ok($self->store->get('Thing'));
}
