# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

package SOAP::Clean::XML;

use Data::Dumper;

use SOAP::Clean::Misc;

use strict;
use warnings;

BEGIN {
  use Exporter   ();
  our (@ISA, @EXPORT);

  @ISA         = qw(Exporter);
  @EXPORT      = qw(
		    $xml_debug;
		    &xml_get_type
		    &document
		    &xml_is_document
		    &xml_document_version
		    &xml_document_encoding
		    &xml_document_element
		    &attr
		    &xml_is_attr
		    &xml_attr_name
		    &xml_attr_value
		    &namespace
		    &xml_is_namespace
		    &xml_namespace_prefix
		    &xml_namespace_urn
		    &text
		    &xml_is_text
		    &xml_text_content
		    &element
		    &xml_is_element
		    &xml_element_name
		    &xml_element_attributes
		    &docinsert
		    &xml_dump
		    &xml_to_file
		    &xml_from_file
		    &xml_from_url
		    &xml_get_children
		    &xml_new_env
		    &xml_get_text
		    &xml_fix_name
		    &xml_get_name
		    &xml_same_urns
		    &xml_same_names
		    &xml_get_attr
		    &xml_get_child
		    &xml_extract_and_close_child
		    &xml_to_fh
		    &xml_to_string
		    &xml_from_fh
		    &xml_from_string		    
		   );
};

our $xml_debug = 0;

########################################################################

sub xml_get_type {
  my ($n) = @_;
  return (ref $n eq "ARRAY") && ($$n[0]);
}

########################################################################

sub document {
  my ($root) = @_;
  return ["&Document", "1.0", "utf-8", $root ];
}

sub xml_is_document {
  my ($n) = @_;
  return xml_get_type($n) eq "&Document";
}

sub xml_document_version {
  my ($n) = @_;
  assert(xml_is_document($n), "Not a document node");
  return $$n[1];
}

sub xml_document_encoding {
  my ($n) = @_;
  assert(xml_is_document($n), "Not a document node");
  return $$n[2];
}

sub xml_document_element {
  my ($n) = @_;
  assert(xml_is_document($n), "Not a document node");
  return $$n[3];
}

########################################################################

sub attr {
  my ($name,$val) = @_;
  return ["&Attr", $name, $val];
}

sub xml_is_attr {
  my ($n) = @_;
  return xml_get_type($n) eq "&Attr";
}

sub xml_attr_name {
  my ($n) = @_;
  assert(xml_is_attr($n), "Not an attribute");
  return $$n[1];
}

sub xml_attr_value {
  my ($n) = @_;
  assert(xml_is_attr($n), "Not an attribute");
  return $$n[2];
}

########################################################################

sub namespace {
  my ($prefix,$uri) = @_;
  if (! $prefix) {
    # Default namespace
    return attr("xmlns",$uri);
  } else {
    return attr("xmlns:".$prefix,$uri);
  }
}

sub xml_is_namespace {
  my ($n) = @_;
  if (!xml_is_attr($n)) { return 0; }
  my $name = xml_attr_name($n);
  return ( $name eq "xmlns" || $name =~ /^xmlns:/ );
}

sub xml_namespace_prefix {
  my ($n) = @_;
  assert(xml_is_namespace($n), "Not a namespace attribute");
  my $name = xml_attr_name($n);
  if ( $name eq "xmlns" ) {
    return "";
  } else {
    assert($name =~ /^xmlns:(.*)/);
    return $1;
  }
}

sub xml_namespace_urn {
  my ($n) = @_;
  assert(xml_is_namespace($n), "Not a namespace attribute");
  return xml_attr_value($n);
}

########################################################################

sub text {
  return [ "&Text", join('',@_) ];
}

sub xml_is_text {
  my ($n) = @_;
  return xml_get_type($n) eq "&Text";
}

sub xml_text_content {
  my ($n) = @_;
  assert(xml_is_text($n), "Not a text");
  return $$n[1];
}

########################################################################

sub element {
  my ($name,@args) = @_;
  assert(!(ref $name));
  my @attrs = ();
  my @children = ();
 CHILD:
  foreach my $arg (@args) {
    if ( $arg == 0 ) {
      next CHILD;
    }
    assert(ref $arg);
    if ( $$arg[0] eq "&Attr" ) {
      push @attrs, $arg;
    } else {
      push @children, $arg;
    }
  }
  return [ $name, 0, [@attrs], @children ];
}

sub xml_is_element {
  my ($n) = @_;
  return (ref $n) eq 'ARRAY' && (xml_get_type($n) !~ /^&/);
}

sub xml_element_name {
  my ($n) = @_;
  assert(xml_is_element($n), "Not an element");  
  return xml_get_type($n);
}

sub xml_element_env {
  my ($n) = @_;
  assert(xml_is_element($n), "Not an element");  
  return $$n[1];
}

sub xml_set_element_env {
  my ($n,$env) = @_;
  assert(xml_is_element($n), "Not an element");  
  $$n[1] = $env;
}

sub xml_element_attributes {
  my ($n) = @_;
  assert(xml_is_element($n), "Not an element");  
  assert(ref($n) eq "ARRAY");
  return @{$$n[2]};
}

sub xml_element_children {
  my ($n) = @_;
  assert(xml_is_element($n), "Not an element");  
  my @results = @$n;
  shift @results;
  shift @results;
  shift @results;
  return @results;
}

sub xml_element_subelements {
  my ($n) = @_;

  my @results = ();
  foreach my $c (xml_element_children($n)) {
    if (xml_is_element($c)) {
      push @results, $c;
    }
  }

  return @results;
}

########################################################################

sub docinsert {
  my ($tmplfile) = @_;
  return xml_document_element(xml_from_file($tmplfile));
}

########################################################################

sub xml_dump {
  my ($n,$i) = @_;
  if (!defined($i)) { $i = 0; }
  assert(0,"fixme");
}

########################################################################

sub xml_to_file {
  my ($e,$filename) = @_;
  assert((open F, ">$filename"),"Cannot open $filename for writing");
  xml_to_fh($e,\*F);
  assert(close F);
}

sub xml_from_file {
  my ($filename) = @_;
  assert((open F, "<$filename"),"Cannot open $filename for reading");
  my $node = xml_from_fh(\*F);
  assert(close F);
  return $node;
}

sub xml_from_url {
  my ($url) = @_;
  my $ua = LWP::UserAgent->new;
  my $request = HTTP::Request->new(GET => $url);
  my $response = $ua->request($request);
  if ( $response->code != 200 ) {
    return;
  } else {
    return xml_from_string($response->content);
  }
}

########################################################################

sub xml_get_text {
  my ($n) = @_;
  my @children;
  if (xml_is_document($n)) {
    @children = ();
  } else {
    @children = xml_element_children($n);
  }

  my $result = '';
  foreach my $c ( @children ) {
    if (xml_is_text($c)) {
      $result .= xml_text_content($c);
    }
  }
  return $result;
}


########################################################################

sub xml_get_children {
  my ($n) = @_;

  my $env;
  my @children;
  if (xml_is_document($n)) {
    $env = {};
    @children = (xml_document_element($n));
  } else {
    $env = xml_element_env($n);
    @children = xml_element_subelements($n);
  }

  if ($env) {
    foreach my $c ( @children ) {
      my $c_env = xml_new_env($env,$c);
      xml_set_element_env($c,$c_env);
    }
  }

  return @children;

}

sub xml_new_env {
  my ($env, $c) = @_;

  # Copy the hash table
  $env = { %$env };

 ATTR:
  foreach my $a ( xml_element_attributes($c) ) {
    if ( !xml_is_namespace($a) ) { next ATTR; }
    my ($prefix,$urn) = (xml_namespace_prefix($a),xml_namespace_urn($a));
    $$env{$prefix} = $urn;
  }

  return $env;
}

########################################################################

sub xml_fix_name {
  my ($n,$name,$is_attr) = @_;

  my $env = xml_element_env($n) || {};

  defined($is_attr) || ($is_attr = 0);

  my ($prefix,$local);
  if ( $name eq "xmlns" ) {
    # special case: "xmlns" -> "xmlns:"
    ($prefix,$local) = ("xmlns","");
  } elsif ( $name =~ /([^:]+):(.*)/ ) {
    ($prefix,$local) = ($1,$2);
  } else {
    ($prefix,$local) = ("",$name);
  }
  my $urn;
  if ( $prefix eq "xmlns" ) {
    # special case: xmlns -> xmlns
    $urn =  "xmlns";
  } elsif ($prefix ne "" ) {
    # If the prefix is non-empty, then look it up.
    $urn = $$env{$prefix};
    if (!defined($urn)) {
      # We didn't find it? Then it cannot possibly match.
      $urn = -1; # -1 won't match with any urn.
    }
  } elsif ($is_attr) {
    # prefix is empty and this is an attribute name. The default
    # namespace does not apply in this case ("Namespaces in XML, 5.2).
    # The attribute name appears in the local namespace;
    $urn = 0;
  } else {
    # prefix is empty and this is not an attribute name. The name
    # appears in the default namespace.
    $urn = $$env{""} || 0;
  }
  assert(defined($urn));

  if ($xml_debug) {
    printf "{%s}%s <- %s\n", $urn, $local, $name;
  }

  return ($urn,$local);
}

sub xml_get_name {
  my ($n) = @_;
  my $t = xml_get_type($n);
  if ($t eq "&Document") {
    assert(0);
    return ();
  } else {
    return xml_fix_name($n,$t);
  }
}

sub xml_same_urns {
  my ($known_urn,$unknown_urn,$not_strict) = @_;

  assert(defined $known_urn);
  assert(defined $unknown_urn);

  # be strict!
  if (!(defined($not_strict) && $not_strict)) {
    return $known_urn eq $unknown_urn;
  } elsif ( ! $unknown_urn ) {
    return 1;
  } else {
    return $known_urn eq $unknown_urn;
  }
}

sub xml_same_names {
  my ($known_urn,$known_name,$unknown_urn,$unknown_name,$not_strict) = @_;
  return ( xml_same_urns($known_urn,$unknown_urn,$not_strict)
	 && $known_name eq $unknown_name);
}

sub xml_get_attr {
  my ($n,$urn,$name,$default) = @_;

  (defined $urn) || assert(0,"Target URN is not defined.");
  (defined $name) || assert(0,"Target name is not defined.");

  foreach my $a (xml_element_attributes($n)) {
    my ($a_urn,$a_name) = xml_fix_name($n,xml_attr_name($a),1);
    if ( xml_same_names($urn,$name,$a_urn,$a_name) ) {
      return xml_attr_value($a);
    }
  }
  return $default;
}

# Fixme: only returns the first matching child
sub xml_get_child {
  my ($n,$urn,$name) = @_;

  (defined $urn) || assert(0,"Target URN is not defined.");
  (defined $name) || assert(0,"Target name is not defined.");

 CHILD:
  foreach my $c (xml_get_children($n)) {
    my ($c_urn,$c_name) = xml_get_name($c);
    if (xml_same_names($urn,$name,$c_urn,$c_name) ) { 
      return $c; 
    }
  }
  return;
}

# fixme - or delete me.
sub xml_extract_and_close_child {
  my ($c) = @_;
  return document($c);
}

########################################################################

#do "SOAP/Clean/XMLTwig.pm" ||
#  die "Can't load SOAP::Clean::XMLTwig. Is XML::Twig installed?";

do "SOAP/Clean/XMLLibxml.pm" || 
  die "Can't load SOAP::Clean::XMLLibxml. Is XML::LibXML installed?";

########################################################################

1;
