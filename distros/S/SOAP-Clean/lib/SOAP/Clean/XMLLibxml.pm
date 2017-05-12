# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

########################################################################
# XML::LibXML document wrappers 
#     - because XML::LibXML is a bit broken...
########################################################################

package SOAP::Clean::XML;

use strict;
use warnings;

use XML::LibXML;

sub libxml_to_perl {
  my ($nn) = @_;
    my $i = $nn->getType();

  if ($i == XML::LibXML::XML_DOCUMENT_NODE) {
    return document(libxml_to_perl($nn->documentElement));
  } elsif ($i == XML::LibXML::XML_ELEMENT_NODE) {
    my @attrs = ();
    foreach my $a ($nn->attributes()) {
      if ( ref $a eq "XML::LibXML::Namespace" ) {
	my $prefix = $a->getName;
	if ( !defined($prefix) ) {
	  push @attrs, attr("xmlns",$a->getData);
	} else {
	  $prefix ne "" || die;
	  push @attrs, attr("xmlns:".$prefix,$a->getData);
	}
      } else {
	push @attrs, attr($a->nodeName,$a->getValue);
      }
    }
    my @children = ();
    foreach my $cc ($nn->childNodes()) {
      my $c = libxml_to_perl($cc);
      if (defined($c)) { 
	push @children, $c;
      }
    }
    return element($nn->nodeName,@attrs,@children);
  } elsif ($i == XML::LibXML::XML_TEXT_NODE) {
    return text($nn->textContent);
  } elsif ($i == XML::LibXML::XML_COMMENT_NODE) {
    return 0;
  } else {
    die "XML_ATTRIBUTE_DECL" if ($i == XML::LibXML::XML_ATTRIBUTE_DECL);
    die "XML_ATTRIBUTE_NODE" if ($i == XML::LibXML::XML_ATTRIBUTE_NODE);
    die "XML_CDATA_SECTION_NODE" if ($i == XML::LibXML::XML_CDATA_SECTION_NODE);
    die "XML_COMMENT_NODE" if ($i == XML::LibXML::XML_COMMENT_NODE);
    die "XML_DOCUMENT_FRAG_NODE" if ($i == XML::LibXML::XML_DOCUMENT_FRAG_NODE);
    die "XML_DOCUMENT_TYPE_NODE" if ($i == XML::LibXML::XML_DOCUMENT_TYPE_NODE);
    die "XML_DTD_NODE" if ($i == XML::LibXML::XML_DTD_NODE);
    die "XML_ELEMENT_DECL" if ($i == XML::LibXML::XML_ELEMENT_DECL);
    die "XML_ENTITY_DECL" if ($i == XML::LibXML::XML_ENTITY_DECL);
    die "XML_ENTITY_NODE" if ($i == XML::LibXML::XML_ENTITY_NODE);
    die "XML_ENTITY_REF_NODE" if ($i == XML::LibXML::XML_ENTITY_REF_NODE);
    die "XML_HTML_DOCUMENT_NODE" if ($i == XML::LibXML::XML_HTML_DOCUMENT_NODE);
    die "XML_NAMESPACE_DECL" if ($i == XML::LibXML::XML_NAMESPACE_DECL);
    die "XML_NOTATION_NODE" if ($i == XML::LibXML::XML_NOTATION_NODE);
    die "XML_PI_NODE" if ($i == XML::LibXML::XML_PI_NODE);
    die "XML_XINCLUDE_END" if ($i == XML::LibXML::XML_XINCLUDE_END);
    die "XML_XINCLUDE_START" if ($i == XML::LibXML::XML_XINCLUDE_START);
    die "XML_???{$i}";
  }
}

sub perl_to_libxml {
  my ($n) = @_;
  my $t = xml_get_type($n);
  if ($t eq "&Document") {
    my $nn = XML::LibXML::Document->new(xml_document_version($n),
					xml_document_encoding($n));
    $nn->setDocumentElement(perl_to_libxml(xml_get_children($n)));
    return $nn;
  } elsif ($t eq "&Attr") {
    die;
  } elsif ($t eq "&Text") {
    my $nn = XML::LibXML::Text->new(xml_text_content($n));
    return $nn;
  } else {
    my $nn = XML::LibXML::Element->new(xml_element_name($n));
    foreach my $a ( xml_element_attributes($n) ) {
      my ($a_name,$a_value) = (xml_attr_name($a),xml_attr_value($a));
      if ( $a_name eq "xmlns" ) {
	$nn->setNamespace($a_value,"",0);
      } elsif ( $a_name =~ /xmlns:(.*)/ ) {
	$nn->setNamespace($a_value,$1,0);
      } else {
	$nn->setAttribute($a_name,$a_value);
      }
    }
    foreach my $c (xml_element_children($n)) {
      $nn->appendChild(perl_to_libxml($c));
    }
    return $nn;
  }
}

########################################################################

sub xml_to_fh {
  my ($e,$fh) = @_;
  my $ee = perl_to_libxml($e);
  print $fh $ee->toString(1),"\n";
}

sub xml_to_string {
  my ($e,$pretty) = @_;
  my $ee = perl_to_libxml($e);
  return $ee->toString($pretty);
}

sub xml_from_fh {
  my ($fh) = @_;
  my $p = new XML::LibXML;
  my $nn = $p->parse_fh($fh);
  my $n = libxml_to_perl($nn);
  $p = $nn = 0;
  return $n;
}

sub xml_from_string {
  my ($str) = @_;
  my $p = new XML::LibXML;
  my $nn = $p->parse_string($str);
  my $n = libxml_to_perl($nn);
  $p = $nn = 0;
  return $n;
}

########################################################################

1;
