#!/usr/bin/perl

##
## Tests for unclassified Pangloss::Segments
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';
use TestSeg qw( test_seg test_and_get_view );

use OpenFrame::Request;
use Pipeline::Segment::Tester;


if (use_ok( 'Pangloss::Segment::StoreRequest' )) {
    my $req = OpenFrame::Request->new;
    my $seg = new Pangloss::Segment::StoreRequest;
    my $pt  = test_seg( $seg, $req );
    ok( $pt->pipe->store->get( 'OriginalRequest' ), ' stores original request' );
}

