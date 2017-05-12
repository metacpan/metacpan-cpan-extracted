#!/usr/bin/perl
# $Id: 20_changemanager.t 418 2007-05-18 00:42:25Z fil $

use strict;
use warnings;

use POE::XUL::Node;
use POE::XUL::ChangeManager;
use Data::Dumper;

use Test::More ( tests=> 9 );

##############################
my $CM = POE::XUL::ChangeManager->new();

ok( $CM, "Created the change manager" );

$POE::XUL::Node::CM = $CM;

##############################
# Test setting the ID

my $b = Button( "Button the first", Click => 'Click1', id=>'B1' );
my $W = Window( id=> 'top', $b );

my $buffer = $CM->flush;

is_deeply( $buffer, [
                     [ 'for', '' ],
                     [ 'new', 'top', 'window', '' ],
                     [ 'new', 'B1', 'button', 'top', 0 ],
                     [ 'set', 'B1', 'label', 'Button the first' ],
                    ],  "Default label" )
    or die Dumper $buffer;

#######
$W->appendChild( Label( 'honk' ) );
pxInstructions( 'empty' );

$buffer = $CM->flush;
is_deeply( $buffer, [],  "Instruction: empty" )
    or die Dumper $buffer;

#######
$W->appendChild( Label( 'honk' ) );
pxInstructions( 'flush', 'timeslice' );
$W->appendChild( Label( 'bonk' ) );

$buffer = $CM->flush;
is_deeply( $buffer, [
                [ 'for', '' ],
                [ 'new', 'PXN1', 'label', 'top', 2 ],
                [ 'textnode', 'PXN1', 0, 'honk' ],
                [ 'timeslice' ],
                [ 'for', '' ],
                [ 'new', 'PXN2', 'label', 'top', 3 ],
                [ 'textnode', 'PXN2', 0, 'bonk' ],
            ],  "Instructions: flush + timeslice" )
    or die Dumper $buffer;

#######
pxInstructions( 'popup_window' );
$buffer = $CM->flush;
is_deeply( $buffer, [
                [ 'popup_window', 'POEXUL000', {} ],
            ],  "Instruction: popup_window w/ defaults" )
    or die Dumper $buffer;

#######
pxInstructions( [ 'popup_window', 'honk' ] );
$buffer = $CM->flush;
is_deeply( $buffer, [
                [ 'popup_window', 'honk', {} ],
            ],  "Instruction: popup_window w/ default features" )
    or die Dumper $buffer;

#######
pxInstructions( [ 'popup_window', 'bonk', {width=>128} ] );
$buffer = $CM->flush;
is_deeply( $buffer, [
                [ 'popup_window', 'bonk', {width=>128} ],
            ],  "Instruction: popup_window" )
    or die Dumper $buffer;


#######
pxInstructions( [ 'popup_window', 'bonk', {width=>128} ], 
                'empty', 
                [ 'timeslice' ] 
              );
$buffer = $CM->flush;
is_deeply( $buffer, [ [ 'timeslice' ] ],  
            "Multiple instructions" )
    or die Dumper $buffer;

#######
my $ML = MenuList();
my $PL = MenuPopup( );
$ML->appendChild( $PL );
$PL->appendChild( MenuItem( value=>"honk", textNode => "Honking" ) );
$PL->appendChild( MenuItem( value=>"PTA", textNode => "Harper Value PTA" ) );
$ML->selectedIndex( 1 );
$PL->lastChild->selected( 1 );
$ML->id( 'CWHat' );


$W->appendChild( $ML );
$buffer = $CM->flush;
$Data::Dumper::Indent = 0;
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;
is_deeply( $buffer, [ [ 'for', '' ],
  [ "new", "PXN3", "menulist", "top", 4 ],
  ["set","PXN3","id","CWHat"],
  [ "new", "PXN4", "menupopup", "CWHat", 0 ],
  [ "new", "PXN5", "menuitem", "PXN4", 0 ],
  [ "set", "PXN5", "value", "honk" ],
  [ "textnode", "PXN5", 0, "Honking" ],
  [ "new", "PXN6", "menuitem", "PXN4", 1 ],
  [ "set", "PXN6", "value", "PTA" ],
  [ "set", "PXN6", "selected", "true" ],
  [ "textnode", "PXN6", 0, "Harper Value PTA" ],
  [ "set", "CWHat", "selectedIndex", 1 ],
],  
            "selectedIndex comes last" )
    or die Dumper $buffer;

