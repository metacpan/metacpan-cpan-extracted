#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('POEx::URI') };

use URI;

my( $uri, $uri2, $base, $rel );

$base = 'poe://kernel/session/';

$uri = URI->new( 'event' );
is( $uri, "event", "event" );
$uri = $uri->abs( $base );

is( $uri, "poe://kernel/session/event", "kernel/session + event" );

##
$base = URI->new( 'poe://kernel/session' );
is( $base->canonical, 'poe://kernel/session/', '->canonical' );

$uri = URI->new( 'event' );
$uri->scheme( 'poe' );
$uri = $uri->abs( $base );

is( $uri, "poe://kernel/session/event", "poe://kernel/session + event" );

##
$uri2 = URI->new( 'poe:event17' );
$uri = $uri2->abs( $base );
is( $uri, "poe://kernel/session/event17", "scheme+event" );

##
$uri = URI->new_abs( 'session2/event2', $base );
is( $uri, "poe://kernel/session2/event2", "poe://kernel/session + event" );


##
$uri = URI->new_abs( 'session/event2', $base );
$uri2 = URI->new_abs( 'event4', $base );

$rel = $uri2->rel( $uri );
is( $rel, "event4", "relative event " );

##
$uri2 = URI->new_abs( 'session3/event3', $base );

$rel = $uri2->rel( $uri );
is( $rel, "/session3/event3", "relative session+event " );

##
$uri2 = URI->new( 'poe://kernel3/session3/event3' );

$rel = $uri2->rel( "$uri" );
is( $rel, "poe://kernel3/session3/event3", "relative kernel+session+event" );

