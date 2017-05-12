#!/usr/bin/perl
# $Id: 22_cm_leaks.t 1023 2008-05-24 03:10:20Z fil $

use strict;
use warnings;

use POE::XUL::Node;
use POE::XUL::ChangeManager;
use Data::Dumper;

use Test::More ( tests=> 9 );

$Data::Dumper::Indent = 1;
$Data::Dumper::Useqq = 1;

my $CM = POE::XUL::ChangeManager->new();
ok( $CM, "Created the change manager" );
$POE::XUL::Node::CM = $CM;

my $b = Button( "Button the first", Click => 'Click1', id=>'B1' );
my $W = Window( id=> 'top', $b );
my $buffer = $CM->flush;

my $before = Dumper $CM;


##############################
# Changing attributes shouldn't leak
$b->setAttribute( selected => 1 );
$b->removeAttribute( 'selected' );
$buffer = $CM->flush;

same_size( $before, $CM, "attribute add/remove" );

$b->setAttribute( selected => 1 );
$buffer = $CM->flush;
$b->removeAttribute( 'selected' );
$buffer = $CM->flush;

same_size( $before, $CM, "attribute add/remove" );

##############################
# Adding then remove a node shouldn't leak
$W->appendChild( 'Hello world' );
$buffer = $CM->flush;
$W->removeChild( 1 );
$buffer = $CM->flush;

same_size( $before, $CM, "child add/remove" );

##############################
# Removing an unknown element is a no-op
diag( "The following warning about an unknown child may be ignored" ) unless $ENV{AUTOMATED_TESTING};
$W->removeChild( 1 );
$buffer = $CM->flush;

same_size( $before, $CM, "removing unknown child" );

##############################
# Add and remove w/o a flush
$W->appendChild( Description( label => 'Honk honk' ) );
$W->removeChild( 1 );

$buffer = $CM->flush;

same_size( $before, $CM, "child add/remove" );

##############################
# Add and remove w/o a flush, this time using a textnode
$W->appendChild( Description( 'Honk honk' ) );
$W->removeChild( 1 );

$buffer = $CM->flush;

same_size( $before, $CM, "textnode add/remove" );

##############################
# Add and remove w/o a flush, this time with a child node
$W->appendChild( GroupBox( Caption( 'Honk honk' ) ) );
$W->removeChild( 1 );

$buffer = $CM->flush;

same_size( $before, $CM, "child-child add/remove" );

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

same_size( $before, $CM, "child add/remove, child change" );



sub same_size
{
    my( $before, $CM, $when ) = @_;

    my $after = Dumper $CM;
    is_deeply( [ split "\n", $before ], 
               [ split "\n", $after ], "Same size after $when" )
        or die "BEFORE=", $before, "\nAFTER=", $after;
}
