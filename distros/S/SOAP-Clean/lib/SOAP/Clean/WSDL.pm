# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

########################################################################
# Some internal routines
########################################################################

package SOAP::Clean::WSDL::Parser;

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use SOAP::Clean::Misc;
use SOAP::Clean::XML;
use SOAP::Clean::Internal;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

sub initialize {
  my ($self) = @_;
}

my $xsd99 = "http://www.w3.org/1999/XMLSchema";

sub reset_parser {
  my ($self) = @_;

  $self->{type_defs} = {};
  $self->_define("type_defs",$xsd,"int",{kind=>"int"});
  $self->_define("type_defs",$xsd,"boolean",{kind=>"boolean"});
  $self->_define("type_defs",$xsd,"float",{kind=>"float"});
  $self->_define("type_defs",$xsd,"base64Binary",{kind=>"base64Binary"});
  $self->_define("type_defs",$xsd,"string",{kind=>"string"});
  $self->_define("type_defs",$xsd,"schema",{kind=>"schema"});

  $self->_define("type_defs",$xsd99,"string",{kind=>"string"});
  $self->_define("type_defs",$xsd99,"float",{kind=>"float"});
  $self->_define("type_defs",$xsd99,"int",{kind=>"int"});

  $self->{message_defs} = {};
  $self->{portType_defs} = {};
  $self->{binding_defs} = {};
  $self->{service_defs} = {};
}

########################################################################

sub _pdie {
  my ($self,$n,$msg) = @_;
  print STDERR "------------------------------------------------------------------------\n";
  print STDERR $msg,"\n";
  print STDERR "Backtrace:\n";
  print STDERR backtrace();
  print STDERR "Offending node:\n";
  print STDERR xml_to_string($n),"\n";
  print STDERR "------------------------------------------------------------------------\n";
  exit 1;
}

########################################################################

sub _define {
  my ($self,$h_name,$urn,$local,$value) = @_;
  my $h = $self->{$h_name};
  $$h{"{$urn}$local"} = $value;
}

sub _lookup {
  my ($self,$h_name,$urn,$local) = @_;
  my $h = $self->{$h_name};
  my $value = $$h{"{$urn}$local"};
  defined($value) || die "No such name - {$urn}$local";
  return $value;
}

########################################################################

sub parse {
  my ($self,$d) = @_;

  reset_parser($self);

  my $definitions = xml_get_child($d,$wsdl,'definitions');
  $definitions || $self->_pdie($d,"No wsdl:definitions?");

  my $definitions_name = xml_get_attr($definitions,0,"name");
  my $definitions_ns = xml_get_attr($definitions,0,"targetNamespace",0);

  my $types;
  my @messages = ();
  my @portTypes = ();
  my @bindings = ();
  my @services = ();

  foreach my $c (xml_get_children($definitions)) {
    my ($urn,$local) = xml_get_name($c);
    xml_same_urns($urn,$wsdl)
      || $self->_pdie($c,"Element not in WSDL namespace");

    if ( $local eq "documentation" ) {
      # ignore documenation
      ;		
    } elsif ( $local eq "import" ) {
      $self->_pdie($c,"wsdl:import not implemented");
    } elsif ( $local eq "types" ) {
      (!defined($types)) || $self->_pdie($c,"Multiple \"types\" elements");
      $types = $c;
    } elsif ( $local eq "message" ) {
      push @messages, $c;
    } elsif ( $local eq "portType" ) {
      push @portTypes, $c;
    } elsif ( $local eq "binding" ) {
      push @bindings, $c;
    } elsif ( $local eq "service" ) {
      push @services, $c;
    } else {
      $self->_pdie($c,"Unexpected \"$local\" element in wsdl:definitions")
    }
  }

  #print ":::::::::::::::::::: types ::::::::::::::::::::\n";
  if (defined($types)) {
    foreach my $schema (xml_get_children($types)) {
      $self->_parse_schema($schema);
    }
  }
  #print Dumper($type_defs),"\n";;

  #print ":::::::::::::::::::: messages ::::::::::::::::::::\n";
  foreach my $message ( @messages ) {
    $self->_parse_message($definitions_ns, $message);
  }
  #print Dumper($message_defs),"\n";;

  #print ":::::::::::::::::::: portType ::::::::::::::::::::\n";
  foreach my $portType ( @portTypes ) {
    $self->_parse_portType($definitions_ns, $portType);
  }
  #print Dumper($portType_defs),"\n";;

  #print ":::::::::::::::::::: binding ::::::::::::::::::::\n";
  foreach my $binding ( @bindings ) {
    $self->_parse_binding($definitions_ns, $binding);
  }
  #print Dumper($binding_defs),"\n";;

  #print ":::::::::::::::::::: service ::::::::::::::::::::\n";
  foreach my $service ( @services ) {
    $self->_parse_service($definitions_ns, $service);
  }
  # print Dumper($service_defs),"\n";;

  return $self->{service_defs};
}

########################################################################

sub _parse_schema {
  my ($self,$schema) = @_;

  xml_same_names($xsd, "schema", xml_get_name($schema))
    || $self->_pdie($schema,"Expected xsd:schema inside wsdl:types");

  # xsd:elementFormDefault
  (xml_get_attr($schema,0,"elementFormDefault","unqualified") 
   eq "qualified")
    || $self->_pdie($schema,"elementFormDefault=unqualified not implemented");

  # xsd:targetNamespace
  my $schema_ns = xml_get_attr($schema,0,"targetNamespace");
  defined ($schema_ns)
    || $self->_pdie($schema,"xsd:schema without a targetNamespace?");

 ELEMENT:
  foreach my $element (xml_get_children($schema)) {
    my @element_name = xml_get_name($element);
    if ( xml_same_names($xsd, "import", @element_name) ) {
      # just ignore it.
      # fixme: we ignore too much.
      next ELEMENT;
    }
    xml_same_names($xsd, "element", @element_name) ||
      $self->_pdie($element,"Not an xsd:element");

    my $type = $self->_parse_schema_element($schema_ns,$element);
    my $name = $$type{name};
    $self->_define("type_defs",$schema_ns,$name,$type);
  }
}

sub _parse_schema_element {
  my ($self,$schema_ns,$element) = @_;

  my $name = xml_get_attr($element,0,"name",0);

  # xsd:nillable
  my $nillable = xml_get_attr($element,0,"nillable","false");
  # xsd:minOccurs
  my $min_occurs = xml_get_attr($element,0,"minOccurs",1);
  # xsd:maxOccurs
  my $max_occurs = xml_get_attr($element,0,"maxOccurs",1);

  my $type;

  # Simple types
  # xsd:type
  my $type_attr = xml_get_attr($element,0,"type");
  if (defined($type_attr)) {
    $type = $self->_lookup("type_defs",xml_fix_name($element,$type_attr));
    goto DONE;
  }

  # xsd:ref
  my $ref_attr = xml_get_attr($element,0,"ref");
  if (defined($ref_attr)) {
    $type = $self->_lookup("type_defs",xml_fix_name($element,$ref_attr));
    goto DONE;
  }

  # complexType
  my @element_children = xml_get_children($element);
  ( $#element_children == 0 ) 
    || $self->_pdie($element,"xsd:element with multiple children?");

  $type = $self->_parse_schema_complexType($schema_ns,$element_children[0]);

 DONE:
  return { kind => "element",
	   namespace => $schema_ns,
	   name => $name,
	   nillable => $nillable,
	   min_occurs => $min_occurs,
	   max_occurs => $max_occurs,
	   basetype => $type
	 };
}

sub _parse_schema_complexType {
  my ($self,$schema_ns,$complexType) = @_;

  xml_same_names($xsd, "complexType", xml_get_name($complexType)) ||
    $self->_pdie($complexType,"Not an xsd:complexType");
    
  # sequence
  my @complexType_children = xml_get_children($complexType);

  # empty sequence - fixme: is this right?
  if ($#complexType_children == -1) {
    return { kind => "sequence", list => [] };
  }

  # non-empty sequence
  ( $#complexType_children == 0 ) 
    || $self->_pdie($complexType,"xsd:complexType with multiple children?");
  my $sequence = $complexType_children[0];
  return $self->_parse_schema_sequence($schema_ns,$sequence);
}

sub _parse_schema_sequence {
  my ($self,$schema_ns,$sequence) = @_;

  xml_same_names($xsd, "sequence", xml_get_name($sequence)) ||
    $self->_pdie($sequence,"Not an xsd:sequence");

  my @sequence_values = ();
  foreach my $c (xml_get_children($sequence)) {
    my @c_name = xml_get_name($c);
    if (xml_same_names($xsd, "element", @c_name)) {
      push @sequence_values, $self->_parse_schema_element($schema_ns,$c);
    } elsif (xml_same_names($xsd, "any", @c_name)) {
      push @sequence_values, { kind => "any" };
    } else {
      $self->_pdie($c,"Not an xsd:element");
    }
  }
  return { kind => "sequence", list => \@sequence_values };
}

########################################################################

sub _parse_message {
  my ($self,$ns,$message) = @_;

  my $message_name = xml_get_attr($message,0,"name");
  defined($message_name) || $self->_pdie($message,"wsdl:message without name?");

  my %parts = ();
  foreach my $part (xml_get_children($message)) {
    xml_same_names($wsdl,"part", xml_get_name($part))
      || $self->_pdie($part,"Expected wsdl:part inside wsdl:message");

    my $part_name = xml_get_attr($part,0,"name");
    defined($part_name) || $self->_pdie($part,"wsdl:part without name?");

    my $type;
    if ( my $element_attr = xml_get_attr($part,0,"element") ) {
      $type = $self->_lookup("type_defs",xml_fix_name($part,$element_attr));
    } elsif ( my $type_attr = xml_get_attr($part,0,"type") ) {
      $type = $self->_lookup("type_defs",xml_fix_name($part,$type_attr));
    } else {
      $self->_pdie($part,"wsdl:part without element or types attribute?");
    }

    $parts{$part_name} = $type;
  }

  $self->_define("message_defs",$ns,$message_name,
	      { __type__ => "message",
		parts => \%parts });
}

########################################################################

sub _parse_portType {
  my ($self,$ns,$portType) = @_;

  my $t;
  my $portType_name = xml_get_attr($portType,0,"name");
  defined($portType_name) || $self->_pdie($portType,"wsdl:portType without name?");

  my %operations = ();
  foreach my $operation (xml_get_children($portType)) {
    xml_same_names($wsdl,"operation", xml_get_name($operation))
      || $self->_pdie($operation,"Expected wsdl:operation inside wsdl:portType");

    my $operation_name = xml_get_attr($operation,0,"name");
    defined($operation_name) || $self->_pdie($operation,"wsdl:operation without name?");

    my $parameter_order = xml_get_attr($operation,0,"parameterOrder",0);

    my @operation_kids = xml_get_children($operation);

    my ($input_name, $input_message);
    my ($output_name, $output_message);
    my @order = ();

    # walk the children looking for input and output elements. skip
    # documentation elements
  KID:
    foreach my $kid ( @operation_kids ) {
      my $kid_kind;
    KIND:
      foreach my $str ( "input","output", "documentation" ) {
	if ( xml_same_names($wsdl,$str, xml_get_name($kid)) ) {
	  $kid_kind = $str;
	  last KIND;
	}
      }
      defined($kid_kind)
	|| $self->_pdie($kid,"Unknown child of wsdl:operation element");
      if ( $kid_kind eq "documentation" ) {
	next KID;
      }

      push @order, $kid_kind;

      my $raw_name = 
	$operation_name.($kid_kind eq "input" ? "Request" : "Response");
      my $name = xml_get_attr($kid,0,"name",$raw_name);
      my $message_attr = xml_get_attr($kid,0,"message");
      defined($message_attr) || $self->_pdie($kid,"wsdl:$kid_kind without wsdl:message attribute?");
      my $message = $self->_lookup("message_defs",xml_fix_name($kid,$message_attr));

      if ($kid_kind eq "input") {
	($input_name, $input_message) = ($name, $message);
      } else {
	($output_name, $output_message) = ($name, $message);
      }

    }

    $operations{$operation_name} = { __type__ => "operation",
				     parameterOrder => $parameter_order,
				     type => "request-response",
				     flits => {
					       $input_name => $input_message,
					       $output_name => $output_message,
					      }
				   };
  }

  $self->_define("portType_defs",$ns,$portType_name,
	      { __type__ => "portType",
		operations => \%operations
	      });
}

########################################################################

sub _parse_binding {
  my ($self,$ns,$binding) = @_;

  my $binding_name = xml_get_attr($binding,0,"name");
  defined($binding_name) || $self->_pdie($binding,"wsdl:binding without name?");

  my $type_attr = xml_get_attr($binding,0,"type");
  defined($type_attr) || $self->_pdie($binding,"wsdl:binding without wsdl:type attribute?");
  my $portType = $self->_lookup("portType_defs",xml_fix_name($binding,$type_attr));
  my $portType_operations = $$portType{operations};

  my @kids = xml_get_children($binding);
  my $protocol_binding = shift @kids;

  foreach my $k ( @kids ) {
    xml_same_names($wsdl, "operation", xml_get_name($k))
      || $self->_pdie($k,"Expected wsdl:operation inside wsdl:binding");
  }

  my $binding_info;
  if (xml_same_names($wsdl_soap,"binding",xml_get_name($protocol_binding))) {
    $binding_info = $self->_parse_soap_binding($ns,$portType_operations,$protocol_binding,@kids);
  } elsif (xml_same_names($wsdl_http,"binding",xml_get_name($protocol_binding))) {
    $binding_info = $self->_parse_http_binding($ns,$portType_operations,$protocol_binding,@kids);
  } else {
    $self->_pdie($binding,"Cannot determine protocol for wsdl:binding");
  }

  $self->_define("binding_defs",$ns,$binding_name,$binding_info);
}

sub _destruct_binding_operation {
  my ($self,$raw_operation,$urn) = @_;
  my $name = xml_get_attr($raw_operation,0,"name");
  defined($name) || $self->_pdie($raw_operation,"wsdl:operation without name?");

  my $protocol_operation = xml_get_child($raw_operation,$urn,"operation");
  defined($protocol_operation)
    || $self->_pdie($raw_operation,"wsdl:operation without $urn:operation");

  my $raw_input = xml_get_child($raw_operation,$wsdl,"input");
  defined($raw_input)
    || $self->_pdie($raw_operation,"wsdl:operation without wsdl:input");

  my $raw_output = xml_get_child($raw_operation,$wsdl,"output");
  defined($raw_output)
    || $self->_pdie($raw_operation,"wsdl:operation without wsdl:output");

  return ($name,$protocol_operation,
	  $name."Request",$raw_input,
	  $name."Response",$raw_output);
}

sub _parse_soap_binding {
  my ($self,$ns,$portType_operations,$protocol_binding,@raw_binding_operations) = @_;
  my $t;

  # soap:style
  my $binding_style = xml_get_attr($protocol_binding,0,"style","document");

  # soap:transport
  my $raw_transport = xml_get_attr($protocol_binding,0,"transport");
  defined($raw_transport) 
    || $self->_pdie($protocol_binding,"no soap:transport attribute in soap:binding?");
  my $transport =
    $raw_transport eq $soaphttp ? "http"
      : ($self->_pdie($protocol_binding,"don't know this value of soap:transport"));

  my %operations = ();
  foreach my $raw_operation ( @raw_binding_operations ) {
    my ($name,$protocol_operation,
	  $default_input_name,$raw_input,
	  $default_output_name,$raw_output) 
      = $self->_destruct_binding_operation($raw_operation,$wsdl_soap);

    my $portType_operation = $$portType_operations{$name};
    defined($portType_operation)
      || $self->_pdie($raw_operation,"Can't find this operation in the portType");
    my $portType_flits = $$portType_operation{flits};

    my $soapAction;
    if ($transport eq "http") {
      $soapAction = xml_get_attr($protocol_operation,0,"soapAction");
      defined($soapAction) ||
	$self->_pdie($protocol_operation,"soapAction attribute required for this operation");
    } else {
      $soapAction = 0;
    }
    my $style = xml_get_attr($protocol_operation,0,"style",$binding_style);

    my $input = $self->_parse_soap_flit($portType_flits,$default_input_name,$raw_input);
    my $output = $self->_parse_soap_flit($portType_flits,$default_output_name,$raw_output);

    $operations{$name} = { __type__ => "binding_operation",
			   soapAction => $soapAction,
			   style => $style,
			   input => $input,
			   output => $output,
			 };
  }

  return { __type__ => "binding",
	   protocol => "soap",
	   operations => \%operations };
}

sub _parse_soap_flit {
  my ($self,$portType_flits,$default_flit_name,$raw_flit) = @_;

  my @x_name = xml_get_name($raw_flit);
  my $in_or_out =
    xml_same_names($wsdl,"input",@x_name) ? "input"
     : (xml_same_names($wsdl,"output",@x_name) ? "output"
	 : $self->_pdie($raw_flit,"Expected wsdl:input or wsdl:output"));

  my $raw_flit_name = xml_get_attr($raw_flit,0,"name",$default_flit_name);
  my $portType_flit = $$portType_flits{$raw_flit_name};
  defined($portType_flit) ||
    $self->_pdie($raw_flit,"Cannot find element name $raw_flit_name in portType");

  my $body = xml_get_child($raw_flit,$wsdl_soap,"body");
  defined($body) || $self->_pdie($raw_flit,"Expected to find a soap:body");
  my $body_parts = xml_get_attr($body,0,"parts",0);
  my $body_use = xml_get_attr($body,0,"use");
  defined($body_use) || $self->_pdie($body,"Expected to find a \"use\" attribute");
  my $body_encodingStyle = xml_get_attr($body,0,"encodingStyle",0);
  my $body_namespace = xml_get_attr($body,0,"namespace",0);

  my $header = xml_get_child($raw_flit,$wsdl_soap,"header");
  (!defined($header)) || $self->_pdie($header,"Need to implement soap:header");

  return { __type__ => "binding_flit",
	   kind => $in_or_out,
	   parts => $body_parts,
	   use => $body_use,
	   encodingStyle => $body_encodingStyle,
	   namespace => $body_namespace,
	   parts => $$portType_flit{parts},
	 };
}

sub _parse_http_binding {
  my ($self,$ns,$portType_operations,$protocol_binding,@raw_binding_operations) = @_;
  return { __type__ => "binding",
	   protocol => "http" };
}

########################################################################

sub _parse_service {
  my ($self,$ns,$service) = @_;

  my $service_name = xml_get_attr($service,0,"name");
  defined($service_name) || $self->_pdie($service,"wsdl:service without name?");

  my %ports = ();
 PORT:
  foreach my $port (xml_get_children($service)) {
    if (xml_same_names($wsdl,"documentation", xml_get_name($port))) {
      next PORT;
    }

    xml_same_names($wsdl,"port", xml_get_name($port))
      || $self->_pdie($port,"Expected wsdl:port inside wsdl:service");

    my $port_name = xml_get_attr($port,0,"name");
    defined($port_name) || $self->_pdie($port,"wsdl:port without name?");

    my $binding_name = xml_get_attr($port,0,"binding");
    defined($binding_name) || $self->_pdie($port,"wsdl:port without binding?");
    my $binding = $self->_lookup("binding_defs",xml_fix_name($port,$binding_name));

    my $port_info = {%$binding};
    $$port_info{__type__} = "port";
    if ( $$binding{protocol} eq "soap" ) {
      $port_info = $self->_parse_soap_port($port_info,$port);
    } elsif ( $$binding{protocol} eq "http" ) {
      $port_info = $self->_parse_http_port($port_info,$port);
    } else {
      die;
    }
    $ports{$port_name} = $port_info;
  }

  $self->_define("service_defs",$ns,$service_name,
	      { __type__ => "service",
		ports => \%ports });
}

sub _parse_soap_port {
  my ($self,$port_info,$port) = @_;

  my $address = xml_get_child($port,$wsdl_soap,"address");
  defined($address) || $self->_pdie($port,"wsdl:port without soap:address?");

  my $location = xml_get_attr($address,0,"location");
  defined($location) || $self->_pdie($address,"Soap:address without soap:address?");
  $$port_info{location} = $location;

  return $port_info;
}

sub _parse_http_port {
  my ($self,$port_info,$port) = @_;

  my $address = xml_get_child($port,$wsdl_http,"address");
  defined($address) || $self->_pdie($port,"wsdl:port without http:address?");

  my $location = xml_get_attr($address,0,"location");
  defined($location) || $self->_pdie($address,"Http:address without http:address?");
  $$port_info{location} = $location;

  return $port_info;
}

########################################################################
########################################################################


package SOAP::Clean::WSDL;

use strict;
use warnings;

BEGIN {
  use Exporter   ();
  our (@ISA, @EXPORT);

  @ISA         = qw(Exporter);
  @EXPORT      = qw(
		    &generate_services
		   );
};

sub generate_services {
  my ($services_defs) = @_;
  my @services = values %$services_defs;
  ($#services == 0) 
    || die "Cannot generate ambiguous service";

  my $service = $services[0];


  my $port = 0;
  foreach my $p (values %{$$service{ports}}) {
    if ( $$p{protocol} eq "soap" ) {
      ($port == 0) || die "Cannot generate ambiguous port";
      $port = $p;
    }
  }
  ($port != 0) || die "Cannot generate ambiguous port";

  return $port;
}

########################################################################

1;
