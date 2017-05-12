#!/usr/bin/env perl
use strict;
use warnings;
use Protocol::SPDY;

my $spdy = Protocol::SPDY::Tracer->new;
$spdy->subscribe_to_event(
	receive_frame => sub { print $_[1] . "\n" }
);
local $/ = \1024;
while(<>) {
	$spdy->on_read($_);
}

