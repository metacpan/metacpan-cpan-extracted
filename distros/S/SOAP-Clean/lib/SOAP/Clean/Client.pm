# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

package SOAP::Clean::Client;

use strict;
use warnings;

use LWP::UserAgent;
use Data::Dumper;

use SOAP::Clean::Misc;
use SOAP::Clean::XML;
use SOAP::Clean::Internal;
use SOAP::Clean::WSDL;

# Inheritance
our @ISA = qw(SOAP::Clean::Internal::Actor);
our $AUTOLOAD;  # it's a package global

sub initialize {
  my ($self,$wsdl_url) = @_;
  $self->SUPER::initialize();
  $self->{wsdl_url} = $wsdl_url;
  LWP::Protocol::implementor('cgifile', 'my_cgifile_handler');
}

sub DESTROY {
  my ($self) = @_;
}

########################################################################

# Set params using WSDL
sub _ensure_wsdl {
  my ($self) = @_;

  if ( defined($self->{port}) ) {
    return;
  }

  # if $self->{port} is not set, then ask the server.
  assert(defined($self->{wsdl_url}), "URL for WSDL not set");

  my $response = $self->_comm(0,$self->{wsdl_url},"GET");

  ($response->code == 200)
    || die("WSDL request failed. Response follows:\n".
	   $response->as_string);

  ($response->content_type eq "text/xml")
    || die("WSDL response was not XML. Response follows:\n".
	   $response->as_string);

  my $wsdl = xml_from_string($response->content);

  # Parse the WSDL
  my $wp = new SOAP::Clean::WSDL::Parser;
  my $service_defs = $wp->parse($wsdl);
  $self->{port} = generate_services($service_defs);
}

########################################################################

sub usage {
  my ($self) = @_;

  $self->_ensure_wsdl();

  my $port = $self->{port};
  my $operations = $$port{operations};

  my $results = {};
  foreach my $method_name (keys %$operations) {
    my $operation = $$operations{$method_name};
    my ($input_args,$output_args);
    if ($$operation{style} eq "rpc") {
      $input_args = $self->usage_rpc_flit($$operation{input});
      $output_args = $self->usage_rpc_flit($$operation{output});
    } elsif ($$operation{style} eq "document") {
      $input_args = $self->usage_document_flit($$operation{input});
      $output_args = $self->usage_document_flit($$operation{output});
    } else {
      die;
    }
    $$results{$method_name} = { input => $input_args,
				output => $output_args };
  }
  return $results;
}

sub usage_rpc_flit {
  my ($self,$flit) = @_;
  my $results = {};
  my $flit_parts = $$flit{parts};
  foreach my $part_name (keys %$flit_parts) {
    my $part_type = $$flit_parts{$part_name};
    $$results{$part_name} = $$part_type{kind};
  }
  return $results;
}


sub usage_document_flit {
  my ($self,$flit) = @_;
  my $results = {};

  assert($$flit{use} eq "literal", "document with non-literal part");

  my $flit_parts = $$flit{parts};
  my @flit_parts_names = keys %$flit_parts;
  assert($#flit_parts_names == 0, "Wrong number of flit parts");
  my $flit_part_name = $flit_parts_names[0];
  my $flit_type = $$flit_parts{$flit_part_name};
  assert($$flit_type{kind} eq "element");
  $flit_type = $$flit_type{basetype};
  assert($$flit_type{kind} eq "sequence");

  foreach my $type ( @{$$flit_type{list}} ) {
    assert($$type{kind} eq "element");
    assert($$type{nillable} eq "false");
    assert($$type{max_occurs} eq "1");
    $$results{$$type{name}} = xsd_type_to_sc($$type{basetype});
    my $optional = ($$type{min_occurs} eq "0");
    if ($optional) {
      $$results{$$type{name}} = "optional ".$$results{$$type{name}};
    }
  }

  return $results;
}

########################################################################

sub AUTOLOAD {
  my $self = shift;
  my $method_name;
  if ( $AUTOLOAD =~ '.*::([^:]+)$' ) {
    $method_name = $1;
  } else {
    $method_name = $AUTOLOAD;
  }
  return $self->invoke($method_name,@_);
}

sub invoke {
  my $self = shift;
  my $method_name = shift;
  my $args = shift;
  # $args is either a hash from arg names to values, or the first
  # argument of the argument list.
  if (ref $args ne "HASH") { 
    $args = [ $args, @_ ];
  }

  $self->_ensure_wsdl();

  my $port = $self->{port};
  my $location = $$port{location};
  my $operations = $$port{operations};
  my $operation = $$operations{$method_name};
  assert(defined($operation),"No such method, $method_name");

  # The base envelope
  my ($request_method,$d);
  if ($$operation{style} eq "rpc") {
    ($request_method,$d) =
      $self->request_rpc($location,$method_name,$operation,$args);
  } elsif ($$operation{style} eq "document") {
    ($request_method,$d) = 
      $self->request_document($location,$method_name,$operation,$args);
  } else {
    die;
  }

  # Encrypt the body and just add it in below, if the enc option was
  # specified
  if (defined($self->{enc})) {
    SOAP::Clean::Security::encrypt_body($d,
					$self->{privkeyenc},
					$self->{pubkeyenc},
					$self->{enctmpl},
					$self->{appl});
  }

  # Sign the envelope
  if (defined($self->{dsig})) { $self->_dsign_envelope($d); }

  # Send it the request envelope and receive the response envelope
  my $request_str = xml_to_string($d,1);
  my $response =
    $self->_comm($method_name,$location,$request_method,
		 { 'Content-Type' => "text/xml",
		   'SOAPAction' => $$operation{soapAction} },
		 $request_str);
  ($response->code == 200)
    || die("SOAP request failed. Response follows:\n".
	   $response->as_string);

  ($response->content_type eq "text/xml")
    || die("SOAP response was not XML. Response follows:\n".
	   $response->as_string);

  $d = xml_from_string($response->content);

  #### DECRYPTION HERE #########

  if (defined($self->{enc})) { $self->_decrypt_body($d); }


  # Extract the results from the response

  my @raw_results;
  if ($$operation{style} eq "rpc") {
    @raw_results = 
      $self->response_rpc($location,$method_name,$operation,$d);
  } elsif ($$operation{style} eq "document") {
    @raw_results = 
      $self->response_document($location,$method_name,$operation,$d);
  } else {
    die;
  }

  if (ref $args eq "HASH") {
    my $results = {};
    while ( $#raw_results >= 0 ) {
      my $k = shift @raw_results;
      my $v = shift @raw_results;
      $$results{$k} = $v;
    }
    return $results;
  } else {
    my @results = ();
    while ( $#raw_results >= 0 ) {
      my $k = shift @raw_results;
      my $v = shift @raw_results;
      push @results,$v;
    }
    return wantarray ? @results : $results[0] ;
  }

}

#########################################################################

sub request_rpc {
  my ($self,$location,$method_name,$operation,$args) = @_;

  my $input = $$operation{input};
  assert($$input{kind} eq "input");
  assert($$input{use} eq "encoded");

  my $input_parts = $$input{parts};
  my @parts = ();
  foreach my $part_name (keys %$input_parts) {
    my $part_type = $$input_parts{$part_name};
    my $part_value;
    if (ref $args eq "HASH") {
      $part_value = $$args{$part_name};
    } else {
      $part_value = shift @$args;
    }
    assert(defined($part_value),"$method_name: $part_name missing");
    push @parts, arg_encode(xsd_type_to_sc($part_type),
			    "server:".$part_name,$part_value);
  }

  # The request
  my $d =
    document
      (element("SOAP-ENV:Envelope",
	       namespace("SOAP-ENV",$SOAP_ENV),
	       namespace("xsi",$xsi),
	       namespace("xsd",$xsd),
	       namespace("server",$$input{namespace}),
	       element("SOAP-ENV:Body",
		       element("server:".$method_name,
			       ($$input{encodingStyle} &&
				attr("SOAP-ENV:encodingStyle",$SOAP_ENC)),
			       @parts))));

  return ('POST',$d);
}

sub response_rpc {
  my ($self,$location,$method_name,$operation,$d) = @_;

  my $output_flit = $$operation{output};
  my $output_parts = $$output_flit{parts};

  my $envelope = xml_get_child($d,$SOAP_ENV,"Envelope");
  assert($envelope);
  my $body = xml_get_child($envelope,$SOAP_ENV,"Body");
  assert($body);
  my @body_kids = xml_get_children($body);
  assert($#body_kids == 0);
  my $container = $body_kids[0];
  assert($container);

  my @results = ();

  foreach my $result ( xml_get_children($container) ) {
    my ($urn,$local) = xml_get_name($result);
    push @results, $local;
    my $part_type = $$output_parts{$local};
    assert(defined($part_type),"Argh! Where is the part-type");
    if ($part_type eq "xml") {
      push @results, arg_decode_to_xml($result);
    } else {
      push @results, arg_decode_to_string($result);
    }
  }
  return wantarray ? @results : $results[0] ;
}

########################################################################

sub request_document {
  my ($self,$location,$method_name,$operation,$args) = @_;

  my $input = $$operation{input};
  assert($$input{kind} eq "input");
  assert($$input{use} eq "literal");

  my $input_parts = $$input{parts};
  my @input_parts_names = keys %$input_parts;
  assert($#input_parts_names == 0, "Wrong number of input parts");
  my $input_part_name = $input_parts_names[0];
  my $input_type = $$input_parts{$input_part_name};
  assert($$input_type{kind} eq "element");
  my $input_name = $$input_type{name};
  my $input_ns = $$input_type{namespace};
  $input_type = $$input_type{basetype};
  assert($$input_type{kind} eq "sequence");

  my @input_formals = ();
  foreach my $input_formal ( @{$$input_type{list}} ) {
    assert($$input_formal{kind} eq "element");
    my $input_formal_name = $$input_formal{name};
    assert($$input_formal{namespace} eq $input_ns,
	   "Arg not in input namespace");
    my $input_formal_value;
    assert($$input_formal{nillable} eq "false");
    assert($$input_formal{max_occurs} eq "1");
    my $optional = ($$input_formal{min_occurs} eq "0");
    if (ref $args eq "HASH") {
      $input_formal_value = $$args{$input_formal_name};
    } else {
      $input_formal_value = shift @$args;
    }
    assert($optional || defined($input_formal_value),
	   "$method_name: $input_formal_name missing");
    if (defined($input_formal_value)) {
      my $input_formal_type = $$input_formal{basetype};
      push @input_formals, arg_encode(xsd_type_to_sc($input_formal_type),
				      "server:".$input_formal_name,
				      $input_formal_value);
    }
  }

  # The request
  my $d =
    document
      (element("SOAP-ENV:Envelope",
	       namespace("SOAP-ENV",$SOAP_ENV),
	       namespace("xsi",$xsi),
	       namespace("xsd",$xsd),
	       namespace("server",$input_ns),
	       element("SOAP-ENV:Body",
		       element("server:".$input_name,
			       ($$input{encodingStyle} &&
				attr("SOAP-ENV:encodingStyle",$SOAP_ENC)),
			       @input_formals))));

  return ('POST',$d);
}

sub response_document {
  my ($self,$location,$method_name,$operation,$d) = @_;

  my $output = $$operation{output};
  assert($$output{kind} eq "output");
  assert($$output{use} eq "literal");

  my $envelope = xml_get_child($d,$SOAP_ENV,"Envelope");
  assert($envelope);
  my $body = xml_get_child($envelope,$SOAP_ENV,"Body");
  assert($body);

  my @body_kids = xml_get_children($body);
  assert($#body_kids == 0);
  my $container = $body_kids[0];
  assert($container);

  my $output_parts = $$output{parts};
  my @output_parts_names = keys %$output_parts;
  assert($#output_parts_names == 0,"Wrong number of output parts");
  my $output_part_name = $output_parts_names[0];
  my $output_type = $$output_parts{$output_part_name};
  assert($$output_type{kind} eq "element");
  my $output_name = $$output_type{name};
  my $output_ns = $$output_type{namespace};
  $output_type = $$output_type{basetype};
  assert($$output_type{kind} eq "sequence");

    my @results = ();
    foreach my $output_formal ( @{$$output_type{list}} ) {
      assert($$output_formal{kind} eq "element");
      my $output_formal_name = $$output_formal{name};
      assert($$output_formal{namespace} eq $output_ns, "Arg not in output namespace");
      my $output_formal_type = $$output_formal{basetype};
      my $result = xml_get_child($container,$output_ns,$output_formal_name);
      assert(defined($result),"$method_name: $output_formal_name missing");
      my $value;
      if (xsd_type_to_sc($output_formal_type) eq 'xml') {
	$value = arg_decode_to_xml($result);
      } else {
	$value = arg_decode_to_string($result);
      }
      push @results, $output_formal_name;
      push @results, $value;
    }
  return @results;
}

########################################################################

sub xsd_type_to_sc {
  my ($type) = @_;
  my $kind = $$type{kind};

  return "int" if ($kind eq "int");
  return "bool" if ($kind eq "boolean");
  return "float" if ($kind eq "float");
  return "raw" if ($kind eq "base64Binary");
  return "string" if ($kind eq "string");
  return "xml" if (is_any($type));

  print Dumper($type);
  return "*unknown*";
}

sub is_any {
  my ($type) = @_;

  ($$type{kind} eq "sequence") || return 0;

  my @list = @{$$type{list}};
  ($#list == 0) || return 0;

  my $x = $list[0];
  ($$x{kind} eq "any") || return 0;

  return 1;
}


########################################################################

1;

