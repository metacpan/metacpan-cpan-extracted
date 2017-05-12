# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

########################################################################
# XML::Twig wrappers
#     - To match the interface in XML.pm
########################################################################

package SOAP::Clean::XML;

use strict;
use warnings;

use File::Temp qw/ :POSIX /;
use XML::Twig;

sub twig_to_perl {
  my ($nn) = @_;

  if (ref $nn eq 'XML::Twig') {
    return document(twig_to_perl($nn->root));
  } elsif ($nn->is_elt) {
    my @attrs = ();
    my $attributes = $nn->atts;
    foreach my $a_name (keys %$attributes) {
      push @attrs, attr($a_name,$$attributes{$a_name});
    }
    my @children = ();
    foreach my $cc ($nn->children) {
      my $c = twig_to_perl($cc);
      if (defined($c)) { 
	push @children, $c;
      }
    }
    return element($nn->tag,@attrs,@children);
  } elsif ($nn->get_type eq '#PCDATA' || $nn->get_type eq '#CDATA') {
    return text($nn->text);
  } else {
    die;
  }
}

sub perl_to_twig {
  my ($n) = @_;
  my $t = xml_get_type($n);
  if ($t eq "&Document") {
    my $nn = XML::Twig->new(pretty_print => 'indented');
    $nn->set_xml_version(xml_document_version($n));
    $nn->set_encoding(xml_document_encoding($n));
    $nn->set_root(perl_to_twig(xml_get_children($n)));
    return $nn;
  } elsif ($t eq "&Attr") {
    die;
  } elsif ($t eq "&Text") {
    my $nn = XML::Twig::Elt->new('#PCDATA');
    $nn->set_text(xml_text_content($n));
    return $nn;
  } else {
    my %attrs = ();
    foreach my $a ( xml_element_attributes($n) ) {
      my ($a_name,$a_value) = (xml_attr_name($a),xml_attr_value($a));
      $attrs{$a_name} = $a_value;
    }
    my @children = ();
    foreach my $c (xml_element_children($n)) {
      push @children, perl_to_twig($c);
    }
    return XML::Twig::Elt->new(xml_element_name($n),
			       \%attrs,@children);
  }
}

########################################################################

sub xml_to_fh {
  my ($e,$fh) = @_;
  my $ee = perl_to_twig($e);
  if (ref $ee eq 'XML::Twig') {
    $ee->print($fh);
  } else {
    $ee->print($fh,'indented');
  }
  print $fh "\n";
}

sub xml_to_string {
  my ($e,$pretty) = @_;
  if (!defined($pretty)) {
    $pretty = 0;
  }
  if (!$pretty) {
    my $ee = perl_to_twig($e);
    return $ee->sprint(1);
  }

  # pretty printing. XML::Twig doesn't give a clean way to do it.

  my $f = tmpnam();
  xml_to_file($e,$f);

  my $result = '';
  assert(open F,"<$f");
  while (my $l = <F>) {
    $result .= $l;
  }
  assert(close F);
  assert(unlink($f));

  return $result;
}

sub xml_from_fh {
  my ($fh) = @_;
  my $nn = XML::Twig->new();
  $nn->parse( $fh );
  my $n = twig_to_perl($nn);
  $nn = 0;
  return $n;
}

sub xml_from_string {
  my ($str) = @_;
  my $nn = XML::Twig->new();
  $nn->parsestring( $str );
  my $n = twig_to_perl($nn);
  $nn = 0;
  return $n;
}

########################################################################

1;
