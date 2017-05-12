#!/usr/bin/perl
# $Id: 10_node.t 1191 2009-02-12 18:28:41Z fil $

use strict;
use warnings;

use POE::XUL::Node;
use POE::XUL::Constants;

use Test::More ( tests=> 88 );

my @tags = qw( 
    ArrowScrollBox Box Button Caption CheckBox ColorPicker Column Columns
    Deck Description Grid Grippy GroupBox HBox Image Label ListBox
    ListCell ListCol ListCols ListHead ListHeader ListItem Menu MenuBar
    MenuItem MenuList MenuPopup MenuSeparator ProgressMeter Radio
    RadioGroup Row Rows Seperator Spacer Splitter Stack StatusBar
    StatusBarPanel Tab TabBox TabPanel TabPanels Tabs TextBox ToolBar
    ToolBarButton ToolBarSeperator ToolBox VBox Window

    HTML_Pre HTML_H1 HTML_H2 HTML_H3 HTML_H4 HTML_A HTML_Div HTML_Br
);

foreach my $tag ( @tags ) {
    my $node = main->can( $tag );
    ok( $node, "Created a $tag" );
}

##########################
my $node = HTML_Div();
is( $node->tag, 'html:div', "Tag names with XML namespace" );

$node->setAttribute( selected=>'true' );
is( $node->getAttribute( 'selected' ), 'true', "logical attributes" );
$node->setAttribute( selected=>0 );
is( $node->getAttribute( 'selected' ), undef() , "logical attributes" );


##########################
$node = Button( "Honk" );
is( $node->label, 'Honk', "Set a default attribute" );

$node = Caption( "Honk Bonk" );
is( $node->label, 'Honk Bonk', "Set a default attribute" );

$node = MenuItem( "biff bonk", id=>'zip' );
is( $node->label, 'biff bonk', "Set a default attribute" );
is( $node->id, 'zip', "With another attribute" );

$node = Radio( "biff" );
is( $node->label, 'biff', "Set a default attribute" );

$node = ListItem( "biff bonk" );
is( $node->label, 'biff bonk', "Set a default attribute" );


##########################
my $js = qq,alert( "The world is my oyster" );,;
$node = Script( $js );
my $xml = $node->as_xml;
is( $xml, qq(<script type='text/javascript'><![CDATA[$js]]></script>), 
            "Script + CDATA" );

##########################
my $lb = ListBox(  rows => 5,
                      ListCols(
                          ListCol(FLEX),
                          Splitter( style=>"width: 0px; border: none; background-color: grey; min-width: 1px;"),
                          ListCol(FLEX),
                          Splitter( style=>"width: 0px; border: none; background-color: grey; min-width: 1px;" ),
                          ListCol(FLEX),
                      ),
                      ListHead(
                              ListHeader(label => 'Name'),
                              ListHeader(label => 'Sex'),
                              ListHeader(label => 'Color'),
                      ),
                      ListItem(
                              ListCell( label => 'Pearl'),
                              ListCell( label => 'Female'),
                              ListCell( label => 'Gray'),
                      ),
                      ListItem(
                              ListCell( label => 'Aramis'),
                              ListCell( label => 'Male'),
                              ListCell( label => 'Black'),
                      ),
                      ListItem(
                              ListCell( label => 'Yakima'),
                              ListCell( label => 'Male'),
                              ListCell( label => 'Holstein'),
                      ),
                      ListItem(
                              ListCell( label => 'Cosmo'),
                              ListCell( label => 'Female'),
                              ListCell( label => 'White'),
                      ),
                );
ok( $lb, "Created a ListBox" );

my $I = $lb->get_item( 1 );
ok( $I, "Got a listitem" );
is( $I->firstChild->label, 'Aramis', " ... and it's Aramis" );

$I = $lb->get_item( 10 );
ok( !$I, "Can't get listitem with wrong index" );

$I = $lb->get_item( -10 );
ok( !$I, "Can't get listitem with wrong index" );

$I = $lb->get_item( 0 );
ok( $I, "Got a listitem" );
is( $I->firstChild->label, 'Pearl', " ... and it's Pearl" );

##########################
$lb->hide();
ok( ($lb->style =~ /display: none/), "Hidden" );
$lb->hide();
my $css = $lb->style;
my @m=($css =~ /display: *none/g);
is( 0+@m, 1, " ... only once" );

$lb->style( "display:none;" );
$lb->hide;
$css = $lb->style;
@m=($css =~ /display: *none/g);
is( 0+@m, 1, " ... only once" );

$lb->show;
$css = $lb->style;
@m=($css =~ /display: *none/g);
is( 0+@m, 0, "Shown" );

$lb->style( "display:none;" );
$lb->show;
$css = $lb->style;
@m=($css =~ /display: *none/g);
is( 0+@m, 0, "Shown" );

##########################
$lb->editable( 1 );
ok( $lb->editable, "Setting editable with Perl true" );
$lb->editable( 'false' );
ok( !$lb->editable, "Setting editable with JS 'false'" );
$lb->editable( 'true' );
ok( $lb->editable, "Setting editable with JS 'true'" );
$lb->editable( '' );
ok( !$lb->editable, "Setting editable with Perl false" );

############################
$node = POE::XUL::Node->new( tag => 'box', honk=>'honk bonk', id=>'zippy' );
is( $node->id, 'zippy', "ID set" );
#use Data::Dumper;
#warn Dumper $node;
$node = POE::XUL::Node->new( 
  'Click' => bless( sub { "DUMMY" }, 'POE::Session::AnonEvent' ),
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
