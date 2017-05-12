#!/usr/bin/perl

use strict;
use warnings;
use Test::More no_plan => 1;

package NewStore;

use strict;
use warnings;

use base qw( Pipeline::Store );

sub set {
  1;
}

sub get {
  1;
}

1;

package MySegment;

use strict;
use warnings;

use base qw( Pipeline::Segment );

sub dispatch {
  main::is(ref(Pipeline::Store->new()), "NewStore");
}

package main;

use_ok('Pipeline');
my $pipe = Pipeline->new();
$pipe->add_segment( MySegment->new() );
$pipe->store( NewStore->new() );
is(ref($pipe->store),'NewStore');
$pipe->dispatch();
my $store = Pipeline::Store::Simple->new();
is(ref($store), 'Pipeline::Store::Simple');

