package Pod::Manual::PodXML2Docbook;

use strict;
use warnings;

use XML::XPathScript::Template;
use XML::XPathScript::Processor;

our $VERSION = '0.08';

our $processor;

our $stylesheet = <<'END_STYLESHEET';
<?xml version="1.0" encoding="iso-8859-1"?>
<%
    $XML::XPathScript::current->interpolating( 0 );
    $Pod::Manual::PodXML2Docbook::processor = $processor;
    $template->import_template( $Pod::Manual::PodXML2Docbook::template );
%>
<%~ / %>
END_STYLESHEET

our $template = XML::XPathScript::Template->new;

$template->set( pod => { content => <<'END_CONTENT' } );
<chapter>
<%~ head %>
<%~ sect1[title/text()="DESCRIPTION"] %>
<%~ sect1[title/text()!="DESCRIPTION"] %>
</chapter>
END_CONTENT

$template->set( head => { 
    showtag => 0,
} );
$template->set( sect1 => { testcode => \&action_sect1 } );
$template->set( "sect$_" => { rename => 'section' } ) for 1..5;

$template->set( 'list' => { testcode => \&tc_list } );

$template->set( code => { 
    pre => '<literal role="code">',
    post => '</literal>' } );

$template->set( strong => { 
    pre => '<emphasis role="bold">',
    post => '</emphasis>' } );

$template->set( emphasis => { 
    pre => '<emphasis role="italic">',
    post => '</emphasis>' } );

$template->set( verbatim => { rename => 'screen' } );

$template->set( title => { 
    showtag => 1,
    testcode => \&tc_title } );

sub tc_title {
    my ( $n, $t ) = @_;

    my $abbrev;
    if ( $n->parentNode->getName eq "sect1" ) {
         ( $abbrev ) = eval { split '-', $n->childNodes->[0]->toString, 2 };
    }

    $t->set({ post => "<titleabbrev>$abbrev</titleabbrev>" }) if $abbrev;

    return   $n->findvalue( 'text()' ) eq 'DESCRIPTION'
           ? $DO_NOT_PROCESS
           : $DO_SELF_AND_KIDS
           ;
}

sub action_sect1 {
    my( $n, $t ) = @_;

    my $title = $n->findvalue( 'title/text()' );

    if ( $title eq 'DESCRIPTION' ) {
        $t->set({ pre => '', showtag => 0 });
    }

    return $title eq 'NAME' ? $DO_NOT_PROCESS : $DO_SELF_AND_KIDS ;
}

$template->set( 'item' => { showtag => 0 } );
$template->set( 'itemtext' => { showtag => 0 } );

sub tc_list {
    my ( $n, $t ) = @_;
    my $output;

    #if ( $n->findnodes( 'item/itemtext' ) ) { # we are a variable list
    #        $output = '<variablelist>';
    #        for my $c ( $n->findnodes('item') ) {
    #            my $item = '<varlistentry>';
    #            $item .= '<term>' . $c->findvalue( 'term/text()' ) . '</term>';
    #            $item .= '<listitem>';
    #            $item .= $processor->apply_templates( $c );
    #            $item .= '</listitem>';
    #            $item .= '</varlistentry>';
    #            $output .= $item;
    #        }
    #        $output .= '</variablelist>';
    #}
    #else {  # we are a itemized list 
    $output = '<itemizedlist>';

    for ( $n->findnodes( 'item' ) ) {
        $output .=  '<listitem>' 
                .   $processor->apply_templates( $_ )
                .   '</listitem>'
                ;
    }

    $output .= '</itemizedlist>';

    #}

    $t->{pre} = $output;

    return $DO_SELF_ONLY;
}

'end of Pod::Manual::PodXML2Docbook';
