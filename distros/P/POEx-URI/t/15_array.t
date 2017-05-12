#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('POEx::URI') };

use URI;
my $uri;

$uri = URI->new('poe:session/event');
is_deeply( [ @$uri ], [ qw( session event ) ], "session+event -> array" );

$uri = URI->new('poe:/session/event');
is_deeply( [ @$uri ], [ qw( session event ) ], "/session+event -> array" );

$uri = URI->new('poe://kernel/session/event');
is_deeply( [ @$uri ], [ qw( poe://kernel/session event ) ], 
        "kernel + session+event -> array" );

$uri = URI->new('poe://kernel/session/event');
is_deeply( [ $uri->as_array ], [ qw( poe://kernel/session event ) ], 
        "as_array" );

$uri = URI->new( 'event', 'poe' );
is_deeply( [ @$uri], [ '', 'event' ], "only event" );

$uri = URI->new( 'session/event', 'poe' );
is_deeply( [ @$uri], [ 'session', 'event' ], "session+event" );

$uri = URI->new( '/session/event', 'poe' );
is_deeply( [ @$uri], [ 'session', 'event' ], "session+event" );
