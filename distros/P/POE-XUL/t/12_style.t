#!/usr/bin/perl
# $Id$

use strict;
use warnings;

use Data::Dumper;
use POE::XUL::Node;
use POE::XUL::Style;
use POE::XUL::ChangeManager;

use Test::More ( tests=> 63 );

my $style = POE::XUL::Style->new();
ok( $style, "Built a style" );

$style->parse( "foo: bar" );
is( $style->as_string, "foo: bar", "Round trip w/o ; OK" );

my $css = <<CSS;
/* comment */
foo: bar;
border: 1px solid blue;
  margin-top: 5px;
/* poor whitespacing, but still legal */
  -moz-border-radius :5px  ;
CSS

$style = POE::XUL::Style->new( $css );
ok( $style, "Built a style" );
is( $style->as_string, $css, "Round trip w/ comments OK" );
is( $style->foo, 'bar', "Found property 'foo'" );
is( $style->border, '1px solid blue', "Found property 'border'" );
is( $style->marginTop, '5px', "Found property 'margin-top'" );
is( $style->MozBorderRadius, '5px', "Found property '-moz-border-radius'" );


$style->foo( 'biffle' );
is( $style->foo, 'biffle', "Set property 'bar'" );

$style->width( 100 );
is( $style->width, 100, "New property 'width'" );

$css =~ s/bar/biffle/;
is( $style, "${css}width: 100;\n", " ... included in text" );

is( $style->borderTop, '1px solid blue', "Found border-top, from border" );


### POE::XUL::Node integration
my $node = Description( style=>$css );
is( $node->style, $css, "Round-trip through node creation" );

$node->style->marginTop( "1em" );
$css =~ s/top: 5px/top: 1em/;
is( $node->style, $css, " ... changed the string" );

$node->style( "honk: bonk" );
is( $node->style, "honk: bonk", "Old-style setting works" );

### helper routines
is( $node->style->display, '', "Default to empty string" );
$node->hide;
is( $node->style->display, 'none', "->hide turns off element" );
ok( $node->hidden, "The node is hidden" );
is( $node->style, "honk: bonk;display: none;\n", "safety ;" );
$node->show;
is( $node->style->display, '', "->show turns it back on" );
ok( !$node->hidden, "The node isn't hidden" );

is( $node->style, "honk: bonk;", "safety ;" );

$node->style( 'display:none' );
ok( $node->hidden, "The node is hidden" );
$css = $node->style;
$css =~ s/display:none;?//;
$node->style( $css );
ok( !$node->hidden, "The node isn't hidden" );
is( $node->style, '', "Style is now empty" );

### padding and margin get some help

$style = POE::XUL::Style->new( <<CSS );
margin: 1px;
padding: 1px 2px;
CSS

is( $style->marginTop, '1px', "got margin-top from margin" );
is( $style->marginBottom, '1px', "got margin-bottom from margin" );
is( $style->marginLeft, '1px', "got margin-left from margin" );
is( $style->marginRight, '1px', "got margin-right from margin" );

is( $style->paddingTop, '1px', "got padding-top from padding" );
is( $style->paddingBottom, '1px', "got padding-bottom from padding" );
is( $style->paddingLeft, '2px', "got padding-left from padding" );
is( $style->paddingRight, '2px', "got padding-right from padding" );

$style = POE::XUL::Style->new( <<CSS );
margin: 1px 2px 3px;
padding: 11px 12px 
13px 14px;
CSS

is( $style->marginTop, '1px', "got margin-top from margin" );
is( $style->marginLeft, '2px', "got margin-left from margin" );
is( $style->marginRight, '2px', "got margin-right from margin" );
is( $style->marginBottom, '3px', "got margin-bottom from margin" );

is( $style->paddingTop, '11px', "got padding-top from padding" );
is( $style->paddingRight, '12px', "got padding-right from padding" );
is( $style->paddingBottom, '13px', "got padding-bottom from padding" );
is( $style->paddingLeft, '14px', "got padding-left from padding" );

$style = POE::XUL::Style->new( <<CSS );
border: thick solid red;
border-top: thin inset blue;
CSS

is( $style->borderWidth, 'thick', "got border-width from border" );
is( $style->borderBottomStyle, 'solid', "got border-bottom-style from border" );
is( $style->borderTopColor, 'blue', "got border-top-color from border-top" );

$style = POE::XUL::Style->new( <<CSS );
border: thick solid red;
border-top: thin inset blue;
border-top-color: orange;
CSS

is( $style->borderTopColor, 'orange', "Didn't got border-top-color from border-top" );
is( $style->borderTop, 'thin inset blue', "But border-top differs ... known lacuna" );

$style = POE::XUL::Style->new( <<CSS );
list-style: circle inside;
-moz-border-radius: 2px 3px;
outline: 1px solid blue;
overflow: scroll;
overflow-x: auto;
CSS

is( $style->listStyleType, 'circle', "Got list-style-type from list-style");
is( $style->listStylePosition, 'inside', "Got list-style-position from list-style");

is( $style->MozBorderRadiusTopleft, '2px', "Got -moz-border-radius-topleft from -moz-border-radius");
is( $style->MozBorderRadiusTopright, '3px', "Got -moz-border-radius-topright from -moz-border-radius");
is( $style->MozBorderRadiusBottomright, '2px', "Got -moz-border-radius-bottomright from -moz-border-radius");
is( $style->MozBorderRadiusBottomleft, '3px', "Got over from -moz-border-radius");

is( $style->outlineColor, 'blue', "Got outline-color from outline" );

is( $style->overflowX, 'auto', "Got overflow-x");
is( $style->overflowY, 'scroll', "Got overflow-y from overflow");

### See how this integrates with the ChangeManager
my $CM = POE::XUL::ChangeManager->new();

$POE::XUL::Node::CM = $CM;
my $div; 
Window( $div = HTML_Div( id=>'honk', style=>"foo: bar;" ) );

my $todo = $CM->flush;
is_deeply( $todo->[-1], [ qw( set honk style ), "foo: bar;" ],
                        "Style seen by CM" );

$div->style->border( '10px' );
$todo = $CM->flush;

my $for = [ 'for', '' ];    # main window

is_deeply( $todo, [ $for, [ qw( style honk border ), "10px" ]],
                        "Style.border change seen by CM" )
                    or die Dumper $todo;

$div->style->borderTop( '10px' );
$todo = $CM->flush;
is_deeply( $todo, [ $for, [ qw( style honk borderTop ), "10px" ]],
                        "Style.borderTop change seen by CM" );

$div->style( "margin: 1em;" );
$todo = $CM->flush;
is_deeply( $todo, [ $for, [ qw( set honk style ), "margin: 1em;" ]],
                        "Style('css') seen by CM" );

$div->hide;
$todo = $CM->flush;
is_deeply( $todo, [ $for, [ qw( style honk display none ) ]],
                        "node->hide seen by CM" );
$div->show;
$todo = $CM->flush;
is_deeply( $todo, [ $for, [ qw( style honk display ), '' ]],
                        "node->show seen by CM" );

$div->hide;
$div->show;
$todo = $CM->flush;
is_deeply( $todo, [ $for, 
                    [ qw( style honk display none ) ],
                    [ qw( style honk display ), '' ]
                  ], "Combined seen by CM" );

$div->hide;
$div->style( 'something: else;' );
$div->style->paddingLeft( 0 );

$todo = $CM->flush;
is_deeply( $todo, [ $for, 
                    [ qw( style honk display none ) ],
                    [ qw( set honk style ), 'something: else;' ],
                    [ qw( style honk paddingLeft 0 ) ]
                  ], "Combined mods in CM" );
# warn Dumper $todo;
