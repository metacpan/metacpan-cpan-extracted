#!/usr/bin/perl
# $Id: 20_changemanager.t 1346 2009-08-28 05:05:51Z fil $

use strict;
use warnings;

use POE::XUL::Node;
use POE::XUL::ChangeManager;
use Data::Dumper;

use Test::More ( tests=> 31 );

##############################
my $CM = POE::XUL::ChangeManager->new();

ok( $CM, "Created the change manager" );

$POE::XUL::Node::CM = $CM;

my $window = Window( id=> 'top' );
ok( $window, "Created top node" );

my $node = $CM->getElementById( 'top' );
ok( $node, "Found the node" );
is_deeply( $node, $window, "Found the node again" );
is_deeply( $CM->{window}, $window, "And it's the window node" );


$window->setAttribute( 'sizetocontent' => 1 );
ok( $node, "Still have a node" );
is_deeply( $node->getAttribute( 'sizetocontent' ), 1, "It's the same node" );

##############################
my $buffer = $CM->flush;
is_deeply( $buffer, [
        [ 'for', '' ],
        [ qw( new top window ), '' ],
        [ qw( set top sizetocontent 1 ) ],
    ], "Got the new stuff" )
            or die Dumper $buffer;

##############################
my $box = HBox( textNode => "hello world" );
$window->appendChild( $box );

$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ qw( new PXN0 hbox top 0) ],
                     [ qw( textnode PXN0 0), "hello world" ]
                    ],  "Only the new stuff" )
    or die Dumper $buffer;

##############################
my $other = VBox( textNode => 'bonk' );
$window->add_child( $other, 0 );

$buffer = $CM->flush;

is_deeply( $buffer, [
                     [ 'for', '' ],
                     [ qw( bye PXN0 ) ],
                     [ qw( new PXN1 vbox top 0 ) ],
                     [ qw( textnode PXN1 0 bonk ) ],
                    ],  "changed nodes" )
    or die Dumper $buffer;

##############################
my $third = VBox( textNode => 'zonk' );
$window->add_child( $third );

$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ qw( new PXN2 vbox top 1 ) ],
                     [ qw( textnode PXN2 0 zonk ) ],
                    ],  "new node changes" )
    or die Dumper $buffer;


##############################
$third->textNode( "don't you loose my number" );

$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ qw( textnode PXN2 0), "don't you loose my number" ],
                    ],  "textNode changes" )
    or die Dumper $buffer;

##############################
# Test mixed mode
$node = Description( "This is a ", HTML_A( "mixed mode" ), " element" );
$window->appendChild( $node );

$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ qw( new PXN4 description top 2 ) ],
                     [ qw( textnode PXN4 0), "This is a " ],
                     [ qw( new PXN3 html:a PXN4 1 ) ],
                     [ qw( textnode PXN3 0 ), 'mixed mode' ],
                     [ qw( textnode PXN4 2 ), ' element' ]
                    ],  "textNode changes" )
    or die Dumper $buffer;


##############################
# Test setting the ID
$CM = POE::XUL::ChangeManager->new();
ok( $CM, "Created the change manager" );
$POE::XUL::Node::CM = $CM;

my $b = Button( "Button the first", Click => 'Click1', id=>'B1' );
my $W = Window( id=> 'top', $b );

$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ 'new', 'top', 'window', '' ],
                     [ 'new', 'B1', 'button', 'top', 0 ],
                     [ 'set', 'B1', 'label', 'Button the first' ],
                    ],  "Default label" )
    or die Dumper $buffer;

##############################
# Test attribute changes
$b->setAttribute( selected => 1 );
$b->removeAttribute( 'selected' );

$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ 'set', 'B1', 'selected', 'true' ],
                     [ 'remove', 'B1', 'selected' ]
                    ],  "Remove an attribute" )
    or die Dumper $buffer;

##############################
# Test textnode manipulation
my $before = Dumper $CM;
$W->appendChild( 'Hello world' );

$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ 'textnode', 'top', 1, 'Hello world' ],
                    ],  "Added a textnode" )
    or die Dumper $buffer;

## Now remove it
$W->removeChild( 1 );

$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ 'bye-textnode', 'top', 1 ],
                    ],  "Removed a textnode" )
    or die Dumper $buffer;

## No-op
diag( "The following warning about an unknown child may be ignored" ) unless $ENV{AUTOMATED_TESTING};
$W->removeChild( 1 );

$buffer = $CM->flush;

is_deeply( $buffer, [],  "No-op" )
    or die Dumper $buffer;

my $after = Dumper $CM;
is( length( Dumper $CM ), length( $before) , "Didn't grow" )
        ;


## Remove one child
$W->removeChild( 0 );

$buffer = $CM->flush;

is_deeply( $buffer, [ [ 'for', '' ], [ qw( bye B1 ) ] ],  "Remove a child" )
    or die Dumper $buffer;


##############################
# Test script and CDATA
my $JS = "this is some JS";
$W->appendChild( Script( $JS ) );
$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ 'new', "PXN5", 'script', 'top', 0 ],
                     [ 'set', "PXN5", 'type', 'text/javascript' ],
                     [ 'cdata', 'PXN5', 0, $JS ]
                    ],  "Javascript + CDATA" )
    or die Dumper $buffer;

## Change the CDATA
my $cdata = $W->firstChild->firstChild;
$JS = "Different JS";
# replaceData
$cdata->replaceData( 0, 100, $JS );
$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ 'cdata', 'PXN5', 0, $JS ]
                    ],  "Changed CDATA" )
    or die Dumper $buffer;

# insertData
$cdata->insertData( 0, "Yet again " );
$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ 'cdata', 'PXN5', 0, "Yet again Different JS" ]
                    ],  "Changed CDATA" )
    or die Dumper $buffer;

# appendData
$cdata->appendData( " man" );
$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ 'cdata', 'PXN5', 0, "Yet again Different JS man" ]
                    ],  "Changed CDATA" )
    or die Dumper $buffer;

# deleteData
$cdata->deleteData( 0, 10 );
$cdata->deleteData( 12, 4 );
$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ],
                     [ 'cdata', 'PXN5', 0, "Different JS" ]
                    ],  "Changed CDATA" )
    or die Dumper $buffer;


##############################
$W->appendChild( Label( 'honk' ) );
$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ], 
                     [ qw( new PXN6 label top 1 ) ], 
                     [ qw( textnode PXN6 0 honk ) ]
                    ],  "Add a child" )
    or die Dumper $buffer;


##############################
$W->appendChild( ListItem( ListCell( label=>'honk' ),
                           ListCell( label=>'bonk' )
                         ) );
$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ], 
                     [ qw( new PXN9 listitem top 2 ) ], 
                     [ qw( new PXN7 listcell PXN9 0 ) ],
                     [ qw( set PXN7 label honk ) ],
                     [ qw( new PXN8 listcell PXN9 1 ) ],
                     [ qw( set PXN8 label bonk ) ],
                    ],  "ListItem" )
    or die Dumper $buffer;


##############################
$node = POE::XUL::Node->new( tag => 'box', honk=>'bonk', id=>'zippy' );
is( $node->id, 'zippy', "ID set" );
#use Data::Dumper;
#warn Dumper $node;
$node = POE::XUL::Node->new( 'Click' => bless( sub { "DUMMY" }, 'POE::Session::AnonEvent' ),
  'class' => 'NOM_ CLIENT-NOM_',
  'id' => 'CLIENT-NOM_',
  'maxlength' => '10',
  'name' => 'CLIENT-NOM_',
  'search' => '!',
  'search-tooltiptext' => 'Recherche de client',
  'size' => -10,
  'value' => ''
);

is( $node->id, 'CLIENT-NOM_', "ID set" );

##############################
$W->scrollTo( 17, 42 );
$buffer = $CM->flush;

is_deeply( $buffer, [[ 'for', '' ], 
                     [ qw( method top scrollTo ), [ 17, 42 ] ], 
                    ],  "scrollTo" )
    or die Dumper $buffer;
