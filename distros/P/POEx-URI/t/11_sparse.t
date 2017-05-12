#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 41;
BEGIN { use_ok('POEx::URI') };

use URI;

my $uri = URI->new('poe:');
ok( $uri, "Built an URI" );

is( $uri->scheme, 'poe', "poe:" );

##
$uri->event( "la" );
is( $uri, "poe:la", "Only event" );
is( $uri->event, 'la', " ... event" );
is( $uri->session, '', " ... session" );
is( $uri->kernel, undef(), " ... kernel" );

$uri->session( "shangri" );
is( $uri, "poe:shangri/la", "session+event" );
is( $uri->event, 'la', " ... event" );
is( $uri->session, 'shangri', " ... session" );
is( $uri->kernel, undef(), " ... kernel" );

$uri->kernel( "ladders" );
is( $uri, "poe://ladders/shangri/la", "kernel+session+event" );
is( $uri->event, 'la', " ... event" );
is( $uri->session, 'shangri', " ... session" );
is( $uri->kernel, 'ladders', " ... kernel" );

##
$uri = URI->new( 'poe:' );
$uri->session( "shangri" );
is( $uri, "poe:shangri/", "Only session" );
is( $uri->event, '', " ... event" );
is( $uri->session, 'shangri', " ... session" );
is( $uri->kernel, undef(), " ... kernel" );

$uri->event( "la" );
is( $uri, "poe:shangri/la", "session+event" );
is( $uri->event, 'la', " ... event" );
is( $uri->session, 'shangri', " ... session" );
is( $uri->kernel, undef(), " ... kernel" );

$uri->event( undef );
$uri->kernel( "ladders" );
is( $uri, "poe://ladders/shangri/", "kernel+session" );
is( $uri->event, '', " ... event" );
is( $uri->session, 'shangri', " ... session" );
is( $uri->kernel, 'ladders', " ... kernel" );

##
$uri = URI->new( 'poe:' );
$uri->kernel( "ladders" );
is( $uri, "poe://ladders", "Only kernel" );
is( $uri->event, '', " ... event" );
is( $uri->session, '', " ... session" );
is( $uri->kernel, 'ladders', " ... kernel" );

# kernel+event makes no sense, skip it

$uri->event( undef );
$uri->session( "shangri" );
is( $uri, "poe://ladders/shangri/", "kernel+session" );
is( $uri->event, '', " ... event" );
is( $uri->session, 'shangri', " ... session" );
is( $uri->kernel, 'ladders', " ... kernel" );

##
$uri = URI->new( 'poe://long/way-to/top' );
$uri->kernel( undef );
is( $uri, "poe:/way-to/top", "-kernel" );
my $uri2 = URI->new( 'poe:way-to/top' );
ok( $uri->eq( $uri2 ), "2 ways to session/event" );

##
$uri->kernel( 'thump' );
$uri->event( undef );
is( $uri, "poe://thump/way-to/", "+kernel-event" );

$uri->kernel( undef );
$uri->event( undef );
is( $uri, "poe:way-to/", "-kernel-event" );

##
$uri->session( undef );
$uri->event( 'honk' );
is( $uri, "poe:honk", "-session-event" );

##
$uri->session( 'honk' );
$uri->session( undef );
is( $uri, "poe:honk", "-session-event" );
