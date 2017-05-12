package Pod::Manual::Docbook2LaTeX;

use strict;
use warnings;

use XML::XPathScript::Template;
use XML::XPathScript::Processor;
use XML::XPathScript::Stylesheet::DocBook2LaTeX;

our $VERSION = '0.08';

our $stylesheet = <<'END_STYLESHEET';
<%
    $XML::XPathScript::current->interpolating( 0 );
    $XML::XPathScript::Stylesheet::DocBook2LaTeX::numbered_sections = 0;
    $Pod::Manual::Docbook2LaTeX::processor = $processor;
    $XML::XPathScript::Stylesheet::DocBook2LaTeX::processor = $processor;
    $template->import_template( $XML::XPathScript::Stylesheet::DocBook2LaTeX::template );
    $template->set( code => { 
        pre  => '<literal role="code">',
        post => '</literal>' 
    } );

    $XML::XPathScript::Stylesheet::DocBook2LaTeX::uniconvs{ord('\\')} = '$\backslash$';
%><%~ / %>
END_STYLESHEET

1;
