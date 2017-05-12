#!/usr/bin/perl
# $Id: 23_cm_cycle.t 1023 2008-05-24 03:10:20Z fil $

use strict;
use warnings;

use POE::XUL::Node;
use POE::XUL::ChangeManager;
use t::PreReq;

use Test::More ( tests=> 17 );
t::PreReq::load( 17, qw( Test::Memory::Cycle ) );

my $CM = POE::XUL::ChangeManager->new();
ok( $CM, "Created the change manager" );
$POE::XUL::Node::CM = $CM;

my $b = Button( "Button the first", Click => 'Click1', id=>'B1' );
my $W = Window( id=> 'top', $b );
my $buffer = $CM->flush;

##############################
# Changing attributes shouldn't leak
$b->setAttribute( selected => 1 );
$b->removeAttribute( 'selected' );
$buffer = $CM->flush;

Test::Memory::Cycle::memory_cycle_ok( $CM );
Test::Memory::Cycle::memory_cycle_ok( $W );

$b->setAttribute( selected => 1 );
$buffer = $CM->flush;
$b->removeAttribute( 'selected' );
$buffer = $CM->flush;

Test::Memory::Cycle::memory_cycle_ok( $CM );
Test::Memory::Cycle::memory_cycle_ok( $W );

##############################
# Adding then remove a node shouldn't leak
$W->appendChild( 'Hello world' );
$buffer = $CM->flush;
$W->removeChild( 1 );
$buffer = $CM->flush;

Test::Memory::Cycle::memory_cycle_ok( $CM );
Test::Memory::Cycle::memory_cycle_ok( $W );

##############################
# Removing an unknown element is a no-op
diag( "The following warning about an unknown child may be ignored" ) unless $ENV{AUTOMATED_TESTING};
$W->removeChild( 1 );
$buffer = $CM->flush;

Test::Memory::Cycle::memory_cycle_ok( $CM );
Test::Memory::Cycle::memory_cycle_ok( $W );

##############################
# Add and remove w/o a flush
$W->appendChild( Description( label => 'Honk honk' ) );
$W->removeChild( 1 );

$buffer = $CM->flush;

Test::Memory::Cycle::memory_cycle_ok( $CM );
Test::Memory::Cycle::memory_cycle_ok( $W );

##############################
# Add and remove w/o a flush, this time using a textnode
$W->appendChild( Description( 'Honk honk' ) );
$W->removeChild( 1 );

$buffer = $CM->flush;

Test::Memory::Cycle::memory_cycle_ok( $CM );
Test::Memory::Cycle::memory_cycle_ok( $W );

##############################
# Add and remove w/o a flush, this time with a child node
$W->appendChild( GroupBox( Caption( 'Honk honk' ) ) );
$W->removeChild( 1 );

$buffer = $CM->flush;

Test::Memory::Cycle::memory_cycle_ok( $CM );
Test::Memory::Cycle::memory_cycle_ok( $W );

##############################
# More complex operation
my $GB = GroupBox( Caption( 'Honk honk', id=>'caption' ) );
$W->appendChild( $GB );
$GB->removeChild( 0 );
$buffer = $CM->flush;
$GB->appendChild( Rows( Row( "honk honk", id=>'row' ), id=>'rows' ) );
$W->removeChild( 1 ); 
undef( $GB );
$buffer = $CM->flush;

Test::Memory::Cycle::memory_cycle_ok( $CM );
Test::Memory::Cycle::memory_cycle_ok( $W );
