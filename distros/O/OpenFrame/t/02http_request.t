#!/usr/bin/perl

##
## -*- Mode: CPerl -*-
##

use strict;
use warnings;

use Test::More no_plan => 1;
use lib './lib';
use OpenFrame::Response;
use Pipeline::Segment::Tester;

use OpenFrame::Cookies;
use OpenFrame::Segment::HTTP::Request;

use HTTP::Request;

$OpenFrame::DEBUG{ ALL } = 1;

## generic
ok(1, "all modules loaded okay");

## create various bits we'll need
my $hr = HTTP::Request->new(GET => "http://opensource.fotango.com");

my $pipe = Pipeline->new();
my $sr = OpenFrame::Segment::HTTP::Request->new()->respond( 1 );

$pipe->debug(0);
$pipe->add_segment( $sr );
$pipe->store->set( $hr );
$pipe->dispatch;

ok($pipe->store->get('OpenFrame::Request'));
ok(my $response = $pipe->store->get('HTTP::Response'));

