#!/usr/bin/perl -w
# $Id$

use strict;

use Test::More ( tests => 18 );
use POE::Component::IKC::Specifier;

my @tests = (

    [ 'session/state', {
            kernel  => '',
            session => 'session',
            state   => 'state'
    } ],
    [ 'state', {
            kernel  => '',
            session => '',
            state   => 'state'
    } ],
    [ '//kernel/session/state', {
            kernel  => 'kernel',
            session => 'session',
            state   => 'state'
    } ],
    [ '//*/session/state', {
            kernel  => '*',
            session => 'session',
            state   => 'state'
    } ],


    [ 'poe://kernel/session/state', {
            kernel  => 'kernel',
            session => 'session',
            state   => 'state',
    } ],
    [ 'poe://kernel/session', {
            kernel  => 'kernel',
            session => 'session',
            state   => ''
    } ],
    [ 'poe://kernel', {
            kernel  => 'kernel',
            session => '',
            state   => ''
    } ],
    [ 'poe:/session/state', {
            kernel  => '',
            session => 'session',
            state   => 'state'
    } ],
    [ 'poe:state', {
            kernel  => '',
            session => '',
            state   => 'state'
    } ],
    [ 'poe://*/session/state', {
            kernel  => '*',
            session => 'session',
            state   => 'state'
    } ],



    [ 'session/state?args', {
            kernel  => '',
            session => 'session',
            state   => 'state',
            args    => 'args',
    } ],
    [ 'state?args', {
            kernel  => '',
            session => '',
            state   => 'state',
            args    => 'args'
    } ],
    [ '//kernel/session/state?args', {
            kernel  => 'kernel',
            session => 'session',
            state   => 'state',
            args    => 'args'
    } ],
    [ '//*/session/state?args', {
            kernel  => '*',
            session => 'session',
            state   => 'state',
            args    => 'args'
    } ],


    [ 'poe://kernel/session/state?args', {
            kernel  => 'kernel',
            session => 'session',
            state   => 'state',
            args    => 'args'
    } ],
    [ 'poe:/session/state?args', {
            kernel  => '',
            session => 'session',
            state   => 'state',
            args    => 'args'
    } ],
    [ 'poe:state?args', {
            kernel  => '',
            session => '',
            state   => 'state',
            args    => 'args'
    } ],
    [ 'poe://*/session/state?args', {
            kernel  => '*',
            session => 'session',
            state   => 'state',
            args    => 'args'
    } ],
);

foreach my $test ( @tests ) {
    my $out = specifier_parse( $test->[0] );
    is_deeply( $out, $test->[1] );
}
