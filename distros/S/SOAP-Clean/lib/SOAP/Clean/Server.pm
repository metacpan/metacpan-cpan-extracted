# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

package SOAP::Clean::Server;

use strict;
use warnings;

use SOAP::Clean::Misc;

BEGIN {
  use Exporter   ();
  our (@ISA, @EXPORT);

  @ISA         = qw(Exporter);
  @EXPORT      = qw(
		    &file
		    &val
		    &in
		    &in_out
		    &out
		    &optional
		    &default
		   );
}

########################################################################
# Parameter constructors
########################################################################

sub param_constructor {
  my $field_name = shift;
  my $field_val = shift;
  my $x = shift;
  if ( !(ref $x) ) {
    my $name = $x;
    my $type = shift;
    $x = { name => $name, type => $type, optional => 0 };
  }
  assert(ref $x eq "HASH");
  $$x{$field_name} = $field_val;
  return $x;
}

sub file { return param_constructor('mech' => 'file',@_); }
sub val { return param_constructor('mech' => 'val',@_); }
sub in { return param_constructor('direc' => 'in',@_); }
sub in_out { return param_constructor('direc' => 'in_out',@_); }
sub out { return param_constructor('direc' => 'out',@_); }

sub optional { return param_constructor('optional' => 1, @_); }

sub default {
  my $default = pop @_;
  return optional(param_constructor('default' => $default, @_));
}

########################################################################
# Base Server
########################################################################

package SOAP::Clean::Server::Base;

use warnings;
use strict;

use File::Temp qw/ :POSIX /;
use MIME::Base64;
use Getopt::Long;

use SOAP::Clean::Misc;
use SOAP::Clean::XML;
use SOAP::Clean::Internal;
use SOAP::Clean::Processes;
use SOAP::Clean::Server;

# Inheritance
our @ISA = qw(SOAP::Clean::Internal::Actor);

# Constructor

sub initialize {
  my ($self) = @_;
  $self->SUPER::initialize();
  $self->{is_server} = 1;
  $self->{verbose} = $ENV{VERBOSE_SERVER} || 0;
  $self->{processes} = new SOAP::Clean::Processes::Basic;
  $self->{urn} = "urn:soap-clean";
  $self->{name} = "unnamed_server";
  $self->{full_name} = "An unnamed SOAP::Clean server";
}

########################################################################
# Methods for modifying object behavior
# ie, new SOAP::Clean::CGI()->descr_file(...)->...
########################################################################

# Methods for defining and describing the server

sub descr_file {
  my ($self,$descr_file) = @_;
  $self->{descr} = $self->_read_descr($descr_file);
  return $self;
}

sub descr {
  my ($self,$descr) = @_;
  $self->{descr} = $descr;
  return $self;
}

sub params {
  my ($self,@params) = @_;
  $self->{params} = \@params;
  return $self;
}

sub command {
  my ($self,$command) = @_;
  $self->{command} = $command;
  return $self;
}

sub urn {
  my ($self,$urn) = @_;
  $self->{urn} = $urn;
  return $self;
}

sub name {
  my ($self,$name) = @_;
  $self->{name} = $name;
  return $self;
}

sub full_name {
  my ($self,$full_name) = @_;
  $self->{full_name} = $full_name;
  return $self;
}

sub in_order {
  my ($self,@in_args) = @_;
  $self->{in_order} = \@in_args;
  return $self;
}

sub out_order {
  my ($self,@out_args) = @_;
  $self->{out_order} = \@out_args;
  return $self;
}

########################################################################

sub _dispatch_method {
  my ($self,$method_name, %request_args) = @_;

  return $self->_Call(%request_args)     if ($method_name eq "Call");
  return $self->_Results(%request_args)  if ($method_name eq "Results");
  return $self->_Running(%request_args)  if ($method_name eq "Running");
  return $self->_Spawn(%request_args)    if ($method_name eq "Spawn");

  die("No such method");
}

########################################################################

sub _Call {
  my ($self,%request_args) = @_;
  
  my $job_info = $self->_do_Spawn(%request_args);
  while ($self->_do_Running($job_info)) {
    sleep 1;
  }
  return $self->_do_Results($job_info);
}

########################################################################

sub _Spawn {
  my ($self,%request_args) = @_;

  my $job_info = $self->_do_Spawn(%request_args);
  my $job_info_str = job_info_to_string($job_info);

  my %response_args = ();
  $response_args{uid} = arg_encode_string('server:uid',$job_info_str);
  return %response_args;
}
  
sub _do_Spawn {
  my ($self,%request_args) = @_;
  
  $self->_ensure_interface();

  my @params = @{$self->{params}};

  my $out_log = tmpnam();

  # Process parameters before calling the command
  my %replacements = ();
  foreach my $p ( @params ) {
    my $name = $$p{name};
    my $direc = $$p{direc};
    my $mech = $$p{mech};
    my $type = $$p{type};
    my $optional = $$p{optional};
    my $default = $$p{default};

    my $replacement;
    if ( $direc eq "out" ) {
      # out parameters
      ( $mech eq "file" ) 
	|| die("Error! file \"".__FILE__."\", line ".__LINE__);
      $replacement = tmpnam();
    } else {
      # in and in_out parameters
      # first, make sure that we have a value.
      my $value;
      if (defined($request_args{$name})) {
	$value = $request_args{$name};
      } elsif (!$optional) {
	die("No value for argument $name");
      } elsif (defined($default)) {
	$value = $default;
      }
      # second, write the value to a file, if need be. Otherwise,
      # convert it to the replacement string
      if ( !defined($value) ) {
	# No value given, so no replacement.
      } elsif ( $mech eq "file" ) {
	$replacement = tmpnam();;
	$self->_write_to_file($value,$type,$replacement);
      } else {
	$replacement = 
	  arg_strip_white
	    (arg_decode_to_string($value));
      }
    }

    if ( defined($replacement) ) {
      $replacements{$name} = $replacement;
    }


  }

  my $command_obj = $self->{command};
  my $cmd_line;
  if (ref $command_obj eq "CODE") {
    $self->_print(1,"Calling code ref to generate commmand line\n");
    $cmd_line = &$command_obj(%replacements);
  } else {
    $cmd_line = $command_obj;
    $self->_print(1,"Raw cmd line: $cmd_line\n");
    $cmd_line =~ s/\$\{(\w+)\}/$replacements{$1}/g;
  }

  $self->_print(1,"Spawning: $cmd_line\n");
  my $processes_obj = assert($self->{processes});
  my $process_info_str = $processes_obj->process_spawn($cmd_line,$out_log);
  $self->_print(1,"Spawned\n");

  my $job_info = [ $process_info_str, $out_log, %replacements ];
  return $job_info;
}

########################################################################

sub _Running {
  my ($self,%request_args) = @_;

  defined($request_args{uid}) || die("Missing uid argument");
  my $job_info_str = arg_decode_to_string($request_args{uid});
  defined($job_info_str) || die("Can't xlate job_info_str");

  my $job_info = job_info_from_string($job_info_str);
  $job_info || die("Invalid job_info string");

  my $running = $self->_do_Running($job_info);

  my %response_args = ();
  $response_args{is_running} = arg_encode_bool('server:is_running',$running);
  return %response_args;
}

sub _do_Running {
  my ($self,$job_info) = @_;

  my ( $process_info_str, $out_log, %replacements ) = @$job_info;
  my $processes_obj = assert($self->{processes});
  my $running = $processes_obj->process_running($process_info_str);
  $self->_print(1,$running ? "Still running\n": "Done!\n");
  return $running;

}

########################################################################

sub _Results {
  my ($self,%request_args) = @_;

  defined($request_args{uid}) || die("Missing uid argument");
  my $job_info_str = arg_decode_to_string($request_args{uid});
  defined($job_info_str) || die("Can't xlate job_info_str");

  my $job_info = job_info_from_string($job_info_str);
  $job_info || die("Invalid job_info string");
  return $self->_do_Results($job_info);
}

sub _do_Results {
  my ($self,$job_info) = @_;
  my ( $process_info_str, $out_log, %replacements ) = @$job_info;

  $self->_ensure_interface();

  my $processes_obj = assert($self->{processes});
  my $status = $processes_obj->process_result($process_info_str);
  $self->_print(1,"Status = $status\n");
  my $out_str = "";
  open LOG, "<$out_log" ||
    die("The command failed. Couldn't read log file");
  while (my $l = <LOG>) {
    $out_str .= $l;
  }
  close LOG;
  unlink($out_log);
  if ( $status != 0 ) {
    die("The command failed. Log follows.\n".$out_str);
  }
  $self->_print(1,"Log follows:\n".$out_str);

  # Process parameters after calling the command
  my @params = @{$self->{params}};
  my @tmp_files = ();
  my %response_args = ();
  foreach my $p ( @params ) {
    my $name = $$p{name};
    my $direc = $$p{direc};
    my $mech = $$p{mech};
    my $type = $$p{type};
    my $replacement = $replacements{$name};

    if ( $mech eq "file" ) {
      push @tmp_files, $replacement;
    }

    if ( $direc eq "in" ) {
      # in parameters
      ; # nothing has to be done.
    } else {
      # out and in_out parameters
      # read the value from a file
      ( $mech eq "file" )
	|| die("Error! file \"".__FILE__."\", line ".__LINE__);
      
      $response_args{$name} = 
	$self->_read_from_file($name,$type,$replacement);
    }
  }

  # Delete the temporary files
  foreach my $f ( @tmp_files ) { unlink $f; }

  return %response_args;
}

########################################################################

sub job_info_to_string {
  my ($job_info) = @_;
  my ( $process_info_str, $out_log, %replacements ) = @$job_info;

  my $str = sprintf("{%s}{%s}",
		    $process_info_str,$out_log);
  foreach my $name ( keys %replacements ) {
    $str .= sprintf("{%s}[%s]",$name,$replacements{$name});
  }
  my $job_info_str = encode_base64($str);
  return $job_info_str;
}

sub job_info_from_string {
  my ($job_info_str) = @_;

  my $str = decode_base64($job_info_str);

  ($str =~ /^\{([^\}]*)\}\{([^\}]*)\}(.*)/) || return 0;
  my $process_info_str = $1;
  my $out_log = $2;
  $str = $3;

  my %replacements = ();
  while ( $str =~ /^\{([^\}]*)\}\[([^\[]*)\](.*)/ ) {
    $replacements{$1} = $2;
    $str = $3;
  }

  ($str eq "") || return 0;
  
  my $job_info = [ $process_info_str, $out_log, %replacements ];
  return $job_info;
}

########################################################################

# Ensure that $self->{params} is properly set for server objects.
sub _ensure_interface {
  my ($self) = @_;

  if ( defined($self->{interface_ensured}) ) { return; }

  if ( defined($self->{params}) &&  defined($self->{command}) ) { 
    ;
  } else {

    assert(!defined($self->{params}),
	   "params() was used, but command() was not");
    assert(!defined($self->{command}),
	   "command() was used, but params() was not");

    defined($self->{descr}) 
      || die("Server descriptor now specified.");

    ($self->{params},$self->{command}) = 
      $self->_parse_descr($self->{descr});
  }

  # Sanity check on the parameters.
  foreach my $p ( @{$self->{params}} ) {
    my $name = assert($$p{name});
    my $direc = assert($$p{direc});
    assert($direc eq 'in' || $direc eq 'out' || $direc eq 'in_out');
    my $mech = assert($$p{mech});
    assert($mech eq 'file' || $mech eq 'val');
    my $type = assert($$p{type});
    assert($type eq 'bool'
	   || $type eq 'int'
	   || $type eq 'float'
	   || $type eq 'string'
	   || $type eq 'raw'
	   || $type eq 'xml');
    if (!defined($$p{optional})) {
      $$p{optional} = 0;
    }
    my $optional = $$p{optional};
    assert(!$optional || ($direc eq 'in' || $direc eq 'in_out'));
    my $default = defined($$p{default});
    assert(!$default || $optional);
  }

  # set in_order, if not already set
  if ( !defined($self->{in_order}) ) {
    my @in_order = ();
    foreach my $param ( @{$self->{params}} ) {
      if ( $$param{direc} ne "out" ) {
	push @in_order, $$param{name};
      }
    }
    $self->{in_order} = \@in_order;
  }

  # set out_order, if not already set
  if ( !defined($self->{out_order}) ) {
    my @out_order = ();
    foreach my $param ( @{$self->{params}} ) {
      if ( $$param{direc} ne "in" ) {
	push @out_order, $$param{name};
      }
    }
    $self->{out_order} = \@out_order;
  }

  $self->{interface_ensured} = 1;

}


########################################################################

sub _write_to_file {
  my ($self,$value,$type,$file) = @_;

  if ( $type eq "xml" ) {
    open F,">$file" ||
      die("Error! file \"".__FILE__."\", line ".__LINE__);
    if ( !ref($value) ) {
      print F $value, "\n";
    } else {
      my $t = arg_decode_to_xml($value);
      xml_to_fh($t,\*F);
    }
    close F ||
      die("Error! file \"".__FILE__."\", line ".__LINE__);
  } elsif ( $type eq "raw" ) {
    open F,">$file" ||
      die("Error! file \"".__FILE__."\", line ".__LINE__);
    binmode F;
    syswrite F, arg_decode_to_string($value);
    close F ||
      die("Error! Line ".__LINE__);

  } else {
    $self->_print(1,"type=$type\n");
    die("Error! file \"".__FILE__."\", line ".__LINE__);
  }
}

########################################################################

sub _read_from_file {
  my ($self,$name,$type,$file) = @_;
  my $result;

  open F, "<".$file
    || die("Error! file \"".__FILE__."\", line ".__LINE__);

  if ($type eq "xml") {
    my $out_doc = xml_from_fh(\*F);
    my ($out_node) = xml_get_children($out_doc);
    $result = arg_encode_xml('server:'.$name,$out_node);
  } elsif ($type eq "raw") {
    binmode F;
    my $out_len = sysseek F,0,2; # how long is the file.
    sysseek F,0,0;		# jump back to the beginning.
    my $out_str;
    sysread F,$out_str,$out_len;
    $result = arg_encode_raw('server:'.$name,$out_str);
  } else {
    # A basic type.
    my $str = "";
    while (<F>) { $str .= $_; }
    if ($type eq "int") {
      $result = arg_encode_int('server:'.$name,$str);
    } elsif ($type eq "string") {
      $result = arg_encode_string('server:'.$name,$str);
    } else {
      $self->_print(1,"name=$name\n");
      $self->_print(1,"type=$type\n");
      $self->_print(1,"file=$file\n");
      die("Error! file \"".__FILE__."\", line ".__LINE__);
    }
  }
  close F;
  return $result;
}

########################################################################
# Generate WSDL
########################################################################

# Generate the basic WSDL result, modulo the 'service' element.

sub _wsdl_generate {
  my ($self,$service_func) = @_;

  $self->_ensure_interface();
  my $params_refs_ref = $self->{params};
  my @params_refs = @$params_refs_ref;

  my $server_urn = $self->{urn};
  defined($server_urn) || die("No server URN");
  my $server_name = $self->{name};
  defined($server_name) || die("No server name");

  my $in_order = $self->{in_order}; assert(defined($in_order));
  my $out_order = $self->{out_order}; assert(defined($out_order));

  ####################################################################
  # types
  ####################################################################

  my %params_by_name = ();
  foreach my $param ( @params_refs ) {
    $params_by_name{$$param{name}} = $param;
  }

  # in parameters type
  my @in_elements = ();
  foreach my $param_name ( @$in_order ) {
    my $param = $params_by_name{$param_name};
    assert(defined($param),"No such parameter $param");
    assert( $$param{direc} ne "out",
	  "$param_name, which appears in in_order(), is an output parameter");
    push @in_elements, 
      $self->_wsdl_parameter_type($$param{name},$$param{type},$$param{optional});
  }
  my $in_type = element("xsd:complexType",
		    element("xsd:sequence",
			    @in_elements));

  # out parameters type
  my @out_elements = ();
  foreach my $param_name ( @$out_order ) {
    my $param = $params_by_name{$param_name};
    assert(defined($param),"No such parameter $param");
    assert( $$param{direc} ne "in",
	  "$param_name, which appears in out_order(), is an input parameter");
    push @out_elements, 
      $self->_wsdl_parameter_type($$param{name},$$param{type},$$param{optional});
  }
  my $out_type = element("xsd:complexType",
			 element("xsd:sequence",
				 @out_elements));

  # UID paramater type
  my $uid_type =
    element("xsd:complexType",
	    element("xsd:sequence",
		    $self->_wsdl_parameter_type("uid","string",0)));

  # is_running:bool parameter type
  my $bool_type =
    element("xsd:complexType",
	    element("xsd:sequence",
		    $self->_wsdl_parameter_type("is_running","bool",0)));

  # The types for the method arguments and results
  my $call_request_type_name = "Call";
  my $call_response_type_name = "CallResult";
  my $spawn_request_type_name = "Spawn";
  my $spawn_response_type_name = "SpawnResult";
  my $running_request_type_name = "Running";
  my $running_response_type_name = "RunningResult";
  my $results_request_type_name = "Results";
  my $results_response_type_name = "ResultsResult";

  my $types = 
    element
      ("types",
       element
       ("xsd:schema",
	attr("elementFormDefault","qualified"),
	attr("targetNamespace",$server_urn),
	$self->_wsdl_generate_types($call_request_type_name,
				    $call_response_type_name,
				    $in_type,$out_type),
	$self->_wsdl_generate_types($spawn_request_type_name,
				    $spawn_response_type_name,
				    $in_type,$uid_type),
	$self->_wsdl_generate_types($running_request_type_name,
				    $running_response_type_name,
				    $uid_type,$bool_type),
	$self->_wsdl_generate_types($results_request_type_name,
				    $results_response_type_name,
				    $uid_type,$out_type),
       ));

  ####################################################################
  # messages
  ####################################################################

  my $call_request_msg_name = "CallRequest";
  my $call_response_msg_name = "CallResponse";
  my $spawn_request_msg_name = "SpawnRequest";
  my $spawn_response_msg_name = "SpawnResponse";
  my $running_request_msg_name = "RunningRequest";
  my $running_response_msg_name = "RunningResponse";
  my $results_request_msg_name = "ResultsRequest";
  my $results_response_msg_name = "ResultsResponse";
  my $fault_msg_name = "Fault";

  my @messages = 
    (

     $self->_wsdl_generate_messages
     ($call_request_type_name,$call_response_type_name,
      $call_request_msg_name,$call_response_msg_name),
     $self->_wsdl_generate_messages
     ($spawn_request_type_name,$spawn_response_type_name,
      $spawn_request_msg_name,$spawn_response_msg_name),
     $self->_wsdl_generate_messages
     ($running_request_type_name,$running_response_type_name,
      $running_request_msg_name,$running_response_msg_name),
     $self->_wsdl_generate_messages
     ($results_request_type_name,$results_response_type_name,
      $results_request_msg_name,$results_response_msg_name),

     element("message",
	     attr("name",$fault_msg_name),
	     element("part",
		     attr("name","faultmess"),
		     attr("type","xsd:string")))

    );

  ####################################################################
  # porttype's
  ####################################################################

  my $porttype_name = $server_name."PortType";

  my $porttype = 
    element("portType",
	    attr("name",$porttype_name),
	    $self->_wsdl_generate_porttype_operation("Call",$call_request_msg_name,
						     $call_response_msg_name),
	    $self->_wsdl_generate_porttype_operation("Spawn",$spawn_request_msg_name,
						     $spawn_response_msg_name),
	    $self->_wsdl_generate_porttype_operation("Running",$running_request_msg_name,
						     $running_response_msg_name),
	    $self->_wsdl_generate_porttype_operation("Results",$results_request_msg_name,
						     $results_response_msg_name));

  ####################################################################
  # bindings
  ####################################################################

  my $binding_name = $server_name."Binding";

  my $binding =
    element
      ("binding",
       attr("name",$binding_name),
       attr("type","server:".$porttype_name),
       element("soap:binding",
	       attr("style","document"),
	       attr("transport",
		    "http://schemas.xmlsoap.org/soap/http")),
       $self->_wsdl_generate_binding_operation("Call"),
       $self->_wsdl_generate_binding_operation("Spawn"),
       $self->_wsdl_generate_binding_operation("Running"),
       $self->_wsdl_generate_binding_operation("Results"));


  ####################################################################
  # Make the service element
  ####################################################################
  my $service = &$service_func($binding_name);

  ####################################################################
  # Put it all together into the WSDL document.
  ####################################################################

  my $d = 
    document
      (element("definitions",
	       namespace(0,$wsdl),
	       namespace("soap",$wsdl_soap),
	       namespace("SOAP-ENC",$SOAP_ENC),
	       namespace("xsd",$xsd),
	       namespace("server",$server_urn),
	       attr("targetNamespace",$server_urn),
	       $types,
	       @messages,
	       $porttype,
	       $binding,
	       $service,
	      ));

  return $d;
}

########################################################################

# Generate type declarations
sub _wsdl_generate_types {
  my ($self,$request_type_name,$response_type_name,
      $request_base_type,$response_base_type) = @_;

  assert($request_type_name);
  assert($response_type_name);
  assert($request_base_type);
  assert($response_base_type);
  
  my $request_type =
    element("xsd:element",
	    attr("name",$request_type_name),
	    $request_base_type);
  my $response_type =
    element("xsd:element",
	    attr("name",$response_type_name),
	    $response_base_type);

  return ($request_type,$response_type);
}

# Generate message declarations
sub _wsdl_generate_messages {
  my ($self,$request_type_name,$response_type_name,
     $request_msg_name,$response_msg_name) = @_;

  my $request_msg =
     element("message",
	     attr("name",$request_msg_name),
	     element("part",
		     attr("name","parameters"),
		     attr("element","server:".$request_type_name)));

  my $response_msg =
     element("message",
	     attr("name",$response_msg_name),
	     element("part",
		     attr("name","parameters"),
		     attr("element","server:".$response_type_name)));

  return ($request_msg,$response_msg);
}


# Generate porttype declarations
sub _wsdl_generate_porttype_operation {
  my ($self,$method_name,$request_msg_name,$response_msg_name) = @_;

  my $operation = 
    element("operation",
	    attr("name",$method_name),
	    element("input", attr("message", "server:".$request_msg_name)),
	    element("output", attr("message","server:".$response_msg_name)));

  return $operation;
}

# Generate binding declarations
sub _wsdl_generate_binding_operation {
  my ($self,$method_name) = @_;

  my $server_urn = $self->{urn};
  defined($server_urn) || die("No server URN");

  my $operation =
       element
       ("operation",
	attr("name",$method_name),
	element("soap:operation",
		attr("soapAction",$server_urn."#".$method_name),
		attr("style","document")),
	element("input",
		element("soap:body",attr("use","literal"))),
	element("output",
		element("soap:body",attr("use","literal")))
       );

  return $operation;
}

# Generate a type element for a single parameter.
sub _wsdl_parameter_type {
  my ($self,$name,$type,$optional) = @_;

  my $type_info;
  if ( $type eq "xml" ) {
    $type_info =
      element("xsd:complexType",
	      attr("mixed","true"),
	      element("xsd:sequence",
		      element("xsd:any")));
  } else {
    my $xsd_type = 0;
    if ( $type eq "bool" ) {
      $xsd_type = "xsd:boolean";
    } elsif ( $type eq "int" ) {
      $xsd_type = "xsd:int";
    } elsif ( $type eq "float" ) {
      $xsd_type = "xsd:float";
    } elsif ( $type eq "string" ) {
      $xsd_type = "xsd:string";
    } elsif ( $type eq "raw" ) {
      $xsd_type = "xsd:base64Binary";
    } else { 
      die("Error! file \"".__FILE__."\", line ".__LINE__); 
    }
    $type_info = attr("type",$xsd_type);
  }

  return element("xsd:element",
		 attr("minOccurs",$optional ? "0" : "1"),
		 attr("maxOccurs","1"),
		 attr("name",$name),
		 $type_info);

}

########################################################################
# Functions for reading and parsing command descriptors.
########################################################################

# Parse a .descr file. Return a "parse object" that describes the contents
# of the file.

sub _read_descr {
  my ($self,$descr_file_name) = @_;

  my $descr = "";
  # read the file. Strip spaces and comments;
  open DESCR_FILE, "<$descr_file_name" ||
    die("Error! file \"".__FILE__."\", line ".__LINE__);
  while (<DESCR_FILE>) {
    chomp;
    # remove comments from the end of the line.
    s/\#[^\"]*$//;
    $descr .= $_;
  }
  close DESCR_FILE ||
    die("Error! file \"".__FILE__."\", line ".__LINE__);

  return $descr;
}

# Returns a list of parameter objects. Each parameter object has these fields,
#
#	name - the name of the parameter
#	direc - one of in, out, in_out
#	mech - How is the parameter communicated to the command?
#		One of val or file
#	type - One of bool, int, float, raw, xml
#	type_arg - Optional argument to the type. Only for type==xml.
#	optional - True if paramater is optional
#	default - Optional, default value

sub _parse_descr {
  my ($self,$descr) = @_;


  my @params = ();
  my $cmd_skel = $descr;

  while ( $cmd_skel =~ '(.*)\[([^\]]*)\](.*)' ) {
    my ($cmd_prefix, $orig_annot, $cmd_suffix) = ($1,$2,$3);

    my $annot = $orig_annot;

    my %param = ();

    ( $annot =~ '^(in|out|in_out)\s+(.*)' )
      || die('Invalid parameter kind - '.$orig_annot);
    ($param{direc},$annot) = ($1,$2);

    if ( $annot =~ '^(val|file)\s+(.*)' ) {
      ($param{mech},$annot) = ($1,$2);
    } else {
      $param{mech} = "val";
    }

    ( $annot =~ '([a-zA-Z0-9_]+)\s*:\s*(.*)' )
      || die('Cannot find parameter name - '.$orig_annot);
    my $param_name;
    ($param_name,$annot) = ($1,$2);

    ( $annot =~ '([^=]+)(.*)' )
      || die('Cannot find type - '.$orig_annot);
    ($param{type},$annot) = ($1,$2);
    $param{type} =~ s/\s//g;
    # type_name("url")
    if ( $param{type} =~ /^([a-zA-Z0-9_-]+)\(\"(.*)\"\)$/ ) {
      ($param{type},$param{type_arg}) = ($1,$2);
    }

    if ( $annot =~ '^=\s*(.*)\s*' ) {
      $param{optional} = 1;
      if ( $1 ne "" ) {
	$param{default} = $1;
      }
    } else {
      $param{optional} = 0;
    }

    $param{name} = $param_name;
    push @params, \%param;
    $cmd_skel = $cmd_prefix.'${'.$param_name.'}'.$cmd_suffix;
  }

  return (\@params,$cmd_skel);
}

########################################################################

1;
