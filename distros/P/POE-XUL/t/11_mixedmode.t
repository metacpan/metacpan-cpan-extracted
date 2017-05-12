#!/usr/bin/perl
# $Id: 11_mixedmode.t 1346 2009-08-28 05:05:51Z fil $

use strict;
use warnings;

use Data::Dumper;
use POE::XUL::Node;

use Test::More ( tests=> 9 );

##########################
my $node = Description( "This is a button" );
my $xml = $node->as_xml;
is( $xml, "<description>This is a button</description>", 
                    "TextNodes" ) or die Dumper $node;

##########################
$node = Window(
        VBox( Description( "hello world" ) ),
        Button( Description( "This is a button" ) )
    );

$xml = $node->as_xml;
is( "$xml\n", <<XML, "TextNodes and so on" ) or die Dumper $node;
<window><vbox>
<description>hello world</description></vbox>
<button><description>This is a button</description></button></window>
XML

##########################
$node = Window (
        Description( "This is a ", HTML_A( "mixed mode" ), " element" )
    );

$xml = $node->as_xml;
is( "$xml\n", <<XML, "Mixed mode!" ) or die Dumper $node;
<window><description>This is a <html:a>mixed mode</html:a> element</description></window>
XML

##########################
my $tn = POE::XUL::TextNode->new( 'MAN!' );
my $b = POE::XUL::Node->new( tag=>'html:b', $tn );

$node->firstChild->appendChild( $b );
$xml = $node->as_xml;
is( "$xml\n", <<XML, "Mixed mode!" ) or die Dumper $node;
<window><description>This is a <html:a>mixed mode</html:a> element<html:b>MAN!</html:b></description></window>
XML

##########################
$node->firstChild->appendChild( " and I feel fine" );
$xml = $node->as_xml;
is( "$xml\n", <<XML, "More mixed-mode mania" ) or die Dumper $node;
<window><description>This is a <html:a>mixed mode</html:a> element<html:b>MAN!</html:b> and I feel fine</description></window>
XML

##########################
my $box = HBox( textNode => "hello world" );
$xml = $box->as_xml;
is( "$xml\n", <<XML, "More mixed-mode mania" ) or die Dumper $box;
<hbox>
hello world</hbox>

XML

##########################
$box->textNode( 'honk' );
$xml = $box->as_xml;
is( "$xml\n", <<XML, "Changing a text node" ) or die Dumper $box;
<hbox>
honk</hbox>

XML

##########################
$box->textNode( $tn );
$xml = $box->as_xml;
is( "$xml\n", <<XML, "Changing a text node" ) or die Dumper $box;
<hbox>
MAN!</hbox>

XML


##########################
$node = Button( "HONK" );
$xml = $node->as_xml;
is( "$xml\n", <<XML, "Default label on a button" ) or die Dumper $node;
<button label='HONK'/>
XML


