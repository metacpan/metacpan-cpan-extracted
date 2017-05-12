#!/usr/bin/perl

# $Id: request_cgi.t,v 1.3 2002/10/12 04:00:22 andreychek Exp $

use strict;
use Test::More  tests => 11;

use lib "./t";
use OpenPluginTests( "get_config" );
use OpenPlugin();

my $data = get_config( "exception", "request_cgi", "log_log4perl" );
my $OP = OpenPlugin->new( config => { data => $data });

# Test 1: Retrieve request object
{
    my $q = $OP->request->object;
    ok( ref $q eq "CGI", "Get Request Object" );
}

# Test 2, 3, 4, 5:  Cookies
{
    my $cookie = {
                name    =>  "TestCookie",
                value   =>  "TestValue",
                domain  =>  "TestDomain.com",
                path    =>  "/test/path",
                expires =>  "+3d",
                secure  =>  "0",
    };

    # Incoming
    $OP->cookie->set_incoming( $cookie );

    my $set_incoming = $OP->cookie->state->{'incoming'}{'TestCookie'};
    $set_incoming->{name} = "TestCookie";
    is_deeply( $set_incoming, $cookie, "Set Incoming Cookie" );

    my $get_incoming = $OP->cookie->get_incoming('TestCookie');
    $get_incoming->{name} = "TestCookie";
    is_deeply( $get_incoming, $cookie, "Get Incoming Cookie" );

    # Outgoing
    $OP->cookie->set_outgoing( $cookie );

    my $set_outgoing = $OP->cookie->state->{'outgoing'}{'TestCookie'};
    $set_outgoing->{name} = "TestCookie";
    is_deeply( $set_outgoing, $cookie, "Set Outgoing Cookie" );

    my $get_outgoing = $OP->cookie->get_outgoing('TestCookie');
    $get_outgoing->{name} = "TestCookie";
    is_deeply( $get_outgoing, $cookie, "Get Outgoing Cookie" );
}

# Test 6, 7, 8, 9
{
    $OP->httpheader->set_incoming('Testing' => "123");
    my $set_incoming = $OP->httpheader->state->{'incoming'}{'Testing'};
    ok( $set_incoming eq "123", "Set Incoming Headers" );

    my $get_incoming = $OP->httpheader->get_incoming('Testing');
    ok( $get_incoming eq "123", "Get Incoming Headers" );

    $OP->httpheader->set_outgoing('Testing' => "789");
    my $set_outgoing = $OP->httpheader->state->{'outgoing'}{'Testing'};
    ok( $set_outgoing eq "789", "Set Outgoing Headers" );

    my $get_outgoing = $OP->httpheader->get_outgoing('Testing');
    ok( $get_outgoing eq "789", "Get Outgoing Headers" );
}

# Test 10, 11
{
    $OP->param->set_incoming('Testing' => "123");
    my $set_param = $OP->param->state->{'param'}{'Testing'};
    ok( $set_param eq "123", "Set Incoming Parameters" );

    my $get_param = $OP->param->get_incoming('Testing');
    ok( $get_param eq "123", "Get Incoming Parameters" );
}
