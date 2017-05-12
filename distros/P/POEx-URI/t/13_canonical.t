#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('POEx::URI') };

use URI;

my( $uri, $uri2, $base, $rel );

##
$uri = URI->new( 'poe://kernel/session' );
is( $uri->canonical, 'poe://kernel/session/', 'kernel + session' );

$uri = URI->new( 'event', 'poe' );
is( $uri->canonical, 'poe:event', 'event' );

$uri = URI->new( 'poe:event' );
is( $uri->canonical, 'poe:event', 'scheme:event' );

$uri = URI->new( 'session/event', 'poe' );
is( $uri->canonical, 'poe:session/event', 'session+event' );

$uri = URI->new( '/session/event', 'poe' );
is( $uri->canonical, 'poe:session/event', '/session+event' );

$uri = URI->new( 'poe:/session/event' );
is( $uri->canonical, 'poe:session/event', 'scheme:/session+event' );


$uri->event(undef);
is( $uri->canonical, 'poe:session/', "session" );

$uri->event( 'event' );

##
$uri->kernel( "SOME-KERNEL" );
is( $uri->canonical, "poe://SOME-KERNEL/session/event", 
                        "No port: is kernel" );

$uri->port( 33100 );
is( $uri->canonical, "poe://some-kernel:33100/session/event", 
                    "Upper->lower case kernel");


$uri->host( 'HELLO.world.com' );
$uri->port( 603 );
is( $uri->canonical, "poe://hello.world.com/session/event", 
                "lower-case host / default port");

