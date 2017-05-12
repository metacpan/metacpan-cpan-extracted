#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

use_ok( class() );
ok( construct() );
ok( add_segment() );
ok( dispatch_method() );
ok( next_segment() );
ok( alternate() );
ok( delete_segment() );


sub class { 'Pipeline::Dispatch' }

sub construct {
  class()->new();
}

sub add_segment {
  construct()->add( new_segment() );
}

sub new_segment {
  MySegment->new();
}

sub delete_segment {
  my $obj = add_segment();
  $obj->delete( 0 );
  my @list = @{$obj->segments()};
  @list == 0;
}

sub next_segment {
  (add_segment()->next())[2] eq 'three';
}

sub dispatch_method {
  construct()->dispatch_method eq 'dispatch'
}

sub alternate {
  add_segment()->dispatch_method( 'dispatch_alternate' )->next
}

package MySegment;

use strict;
use warnings;
use base qw( Pipeline::Segment );

sub dispatch { main::ok(1); return ('one','two','three') }
sub dispatch_alternate { main::ok( 1 ) }
