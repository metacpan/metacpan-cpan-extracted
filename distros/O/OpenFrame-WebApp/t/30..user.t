#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::User
##

use blib;
use strict;
use warnings;

use Test::More qw( no_plan => 1 );

BEGIN { use_ok("OpenFrame::WebApp::User") };
BEGIN { use_ok("OpenFrame::WebApp::User::Factory") };

ok( keys( %{ OpenFrame::WebApp::User->types } ), 'default types' );

ok( OpenFrame::WebApp::User->types->{webapp}, 'webapp registered' );

my $user = new OpenFrame::WebApp::User;
ok( $user, "new" ) || die( "can't create new user!" );

is( $user->id('test'), $user, "id(set)" );
is( $user->id, 'test',        "id(get)" );


my $ufactory = new OpenFrame::WebApp::User::Factory;
ok( $ufactory, "new" ) || die( "can't create new user factory!" );

my $user2 = $ufactory->type('webapp')->new_user();
ok( $user2, "factory new" ) || die( "can't create new user!" );

