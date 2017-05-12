#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Pipeline;

my $pipe = Pipeline->new();
$pipe->add_segment(
		   MySegmentPlacer->new(),
		   MySegmentFetcher->new()
		  );

$pipe->dispatch();

$pipe->dispatcher()->next( $pipe );
ok(Pipeline::Store::Simple->new() != $pipe->store);

$pipe->add_segment( Pipeline->new()->add_segment(
						 MySegmentFetcher->new()
						)
		  );
$pipe->dispatch();





package MySegmentPlacer;

use strict;
use warnings;
use Pipeline::Segment;
use base qw( Pipeline::Segment );

sub dispatch {
  my $self = shift;
  $self->store->set(bless({},'Some::Class'));
}

package MySegmentFetcher;

use strict;
use warnings;
use Pipeline::Segment;
use base qw( Pipeline::Segment );

sub dispatch {
  my $self = shift;
  $self->store->get('Some::Class');
  my $newstore = Pipeline::Store->new();
  main::ok($self->store->get('Some::Class') == $newstore->get('Some::Class'));
}

1;
