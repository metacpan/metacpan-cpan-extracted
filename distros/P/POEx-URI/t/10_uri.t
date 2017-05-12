#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 51;
BEGIN { use_ok('POEx::URI') };

use URI;

my $uri = URI->new( "poe://something/other/what" );
ok( $uri, "Built a URI" );

isa_ok( $uri, "URI::poe", "A POE URI" );

##
is( $uri->scheme, 'poe', "poe:" );
is( $uri->kernel, 'something', "poe://kernel" );
is( $uri->session, 'other', "poe://kernel/session" );
is( $uri->event, 'what', "poe://kernel/session/event" );

is( $uri->canonical, "poe://something/other/what", "Same kernel");

##
$uri->session( 'honk' );
is( $uri, "poe://something/honk/what", "Changed session");
$uri->event( 'honk' );
is( $uri, "poe://something/honk/honk", "Changed event");
$uri->kernel( 'honk' );
is( $uri, "poe://honk/honk/honk", "Changed kernel");

##
$uri->session( qw( hello world ) );
is( $uri, "poe://honk/hello/honk", "Path-like session");
$uri->session( "hello/wor;ld" );
is( $uri, "poe://honk/hello%2Fwor%3Bld/honk", "Path-like session");
$uri->session( "#1" );
is( $uri, "poe://honk/%231/honk", "Numbered session");

is( $uri->path, "/%231/honk", "path" );
is_deeply( [ $uri->path_segments ], [ '', '#1', 'honk' ], "path_segments" );


##
$uri->kernel( "other-kernel" );
is( $uri, "poe://other-kernel/%231/honk", "Harder kernel");
$uri->kernel( "other/kernel" );
is( $uri, "poe://other%2Fkernel/%231/honk", "/ in kernel");
$uri->kernel( "127.0.0.1" );
is( $uri->canonical, "poe://127.0.0.1/%231/honk", "IP of kernel");

##
$uri->kernel( "SOME-HOST:33100" );
is( $uri->host, 'SOME-HOST', "Host name" );
is( $uri->port, 33100, "Port number" );

$uri->host( 'HELLO.world.com' );
is( $uri->host, 'HELLO.world.com', "Changed host" );
is( $uri->kernel, 'HELLO.world.com:33100', "But not the port" );

$uri->port( 603 );
is( $uri->kernel, 'HELLO.world.com:603', "Changed the port" );
is( $uri->port, 603, "Both places" );

$uri = $uri->canonical;


##
$uri->userinfo( "rambling:man" );
is( $uri, "poe://rambling:man\@hello.world.com/%231/honk", "Added user info");

is( $uri->user, 'rambling', "Got just the user" );
is( $uri->password, 'man', "Got just the password" );

$uri->user( 'rambling:man' );
is( $uri, "poe://rambling%3Aman:man\@hello.world.com/%231/honk", 
                    "Changed user");
is( $uri->user, 'rambling:man', "Unescaped" );

$uri->password( 'rambling:man' );
is( $uri, "poe://rambling%3Aman:rambling%3Aman\@hello.world.com/%231/honk", 
                    "Changed password");
is( $uri->password, 'rambling:man', "Unescaped" );

is( $uri->userinfo, "rambling%3Aman:rambling%3Aman", "Both bits");

##
$uri->password(undef);
is( $uri->userinfo, "rambling%3Aman", "No password");
is( $uri->password, undef(), "At all");
is( $uri->user, "rambling:man", "But have a user");

##
$uri->password( "foo:bar" );
$uri->user(undef);
is( $uri->userinfo, ":foo%3Abar", "No user");
is( $uri->user, '', "At all");
is( $uri->password, "foo:bar", "But have a password");

##
$uri->password( '' );
$uri->user( '' );
is( $uri->userinfo, ":", "No user nor password");
$uri->password( undef );
$uri->user( undef );
is( $uri->userinfo, undef, "None defined");

##
$uri->path( "/foo/bar/baz" );
is( $uri, "poe://hello.world.com/foo%2Fbar/baz", "Messy path -> session/event" );
$uri->path( "in-flames" );
is( $uri, "poe://hello.world.com/in-flames", "Messy path, no event" );
$uri->path( "/in-flames" );
is( $uri, "poe://hello.world.com/in-flames", "No event" );

##
$uri->path_segments( qw( hello world ) );
is( $uri, "poe://hello.world.com/hello/world", "path_segments" );
$uri->path_segments( '', qw( I fight ) );
is( $uri, "poe://hello.world.com/I/fight", "3 path_segments" );
$uri->path_segments( qw( I'm a problem child ) );
is( $uri, "poe://hello.world.com/I'm%2Fa%2Fproblem/child", "Multiple path_segments" );

is_deeply( [ $uri->path_segments ],
           [ '', qw( I'm/a/problem child ) ],
            "Got all the pieces back"
         );

##
$uri->event( 'foo/bar' );
is( $uri, "poe://hello.world.com/I'm%2Fa%2Fproblem/foo%2Fbar", 
        "Slash in event" );

##
$uri->path( "/foo/bar/baz" );
is( $uri, "poe://hello.world.com/foo%2Fbar/baz", "Slash in session" );

$uri = URI->new( "poe:/foo/bar/baz" )->canonical;
is( $uri, "poe:foo%2Fbar/baz", "Canonical" );
