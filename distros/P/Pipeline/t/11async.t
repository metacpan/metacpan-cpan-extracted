#!/usr/bin/perl

use strict;
use warnings;


use Test::More no_plan => 1;
use Pipeline::Dispatch;
use Pipeline::Segment::Async;

ok( construct() );
ok( runasync() );

sub construct { class()->new() }
sub class { "Pipeline::Segment::Async" }

sub runasync {
  my $pipe = Pipeline->new();
  ok($pipe->store->set(bless({},'AnObject')),"object placed in store");
  $pipe->add_segment( Async::Segment->new() );
  ok($pipe->dispatch(),"dispatch completed");
  ok(my $seg = $pipe->store->get('Async::Segment'), "get seg out");
  ok(1, "used model " . ref($seg->model));
  ok($seg->reattach(), "reattached async segment");
}



package Async::Segment;

use strict;
use warnings;

use base qw( Pipeline::Segment::Async );

sub dispatch {
  my $self = shift;
  $self->store->get('AnObject');
  $self->store->set(bless({},'AsyncdObject'));
  my $i = 0;
  while( $i < 1000000 ) {
    $i++
  }
  return 1;
}

1;
