#!/usr/bin/perl

# $Id: session_apachesession.t,v 1.3 2002/10/12 04:00:22 andreychek Exp $

use strict;
use Test::More  tests => 5;

use lib "./t";
use OpenPluginTests( "get_config" );
use OpenPlugin();

my $data = get_config( "exception", "session_apachesession", "log_log4perl" );
my $OP = OpenPlugin->new( config => { data => $data });

my $session_id = $OP->session->create();
ok( $session_id, "Initiate Session" );

my $session = {
    test    => "123",
    test2   => "Chinese Chicken Salad",
};

my $ret_val = $OP->session->save( $session );
ok( $ret_val, "Save Session Data" );

my $fetched_session = $OP->session->fetch( $session_id );
my $test_session_data       = {};
my @test_session_internals;
my $session_internals = "_accessed _expires _session_id _start";

foreach ( keys %{ $fetched_session } ) {
    push @test_session_internals, $_  if m/^_/;
    $test_session_data->{ $_ } = $fetched_session->{ $_ } unless m/^_/;
}

is_deeply( $session, $test_session_data, "Retrieve Session Values" );

my $test_session_internals = join ' ', sort @test_session_internals;
ok( $session_internals eq $test_session_internals, "Create Session Metadata" );

ok( $OP->session->delete(), "Delete Session" );
