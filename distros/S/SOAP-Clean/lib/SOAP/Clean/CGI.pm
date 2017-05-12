# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

########################################################################
# CGI Server
########################################################################

# Determine invocation method
# Extract method name and arguments
# call appropriate method

package SOAP::Clean::CGI;

use warnings;
use strict;

use Getopt::Long;
use File::Basename;

use SOAP::Clean::Misc;
use SOAP::Clean::XML;
use SOAP::Clean::Internal;
use SOAP::Clean::Server;

use CGI qw/:standard/;

# Inheritance
our @ISA = qw(SOAP::Clean::Server::Base);

BEGIN {

  # if $REQUEST_METHOD isn't set, then assume that the script was
  # called interactively. Parse the command line and set the
  # environment variables accordingly.
  if ( !defined($ENV{REQUEST_METHOD}) ) {

    $ENV{SERVER_PROTOCOL}='HTTP/1.1';
    $ENV{HTTP_HOST}='localhost.localdomain:80';
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{REQUEST_URI} = $0;
    $ENV{VERBOSE_SERVER} = 0;

    my $help = 0;
    my $verbose = 0;
    my $stat =
      GetOptions('help' => \$help,
		 'get|G' => sub { $ENV{REQUEST_METHOD} = 'GET' },
		 'post|P' => sub { $ENV{REQUEST_METHOD} = 'POST' },
		 'type=s' => sub { $ENV{CONTENT_TYPE} = $_[1] },
		 'soap_action:s' => sub { 
		   if (defined($ENV{HTTP_SOAPACTION})) {
		     $ENV{HTTP_SOAPACTION} = $_[1];
		   } else {
		     $ENV{HTTP_SOAPACTION} = "urn:something/bogus";
		   }
		 },
		 'query=s' => sub { $ENV{QUERY_STRING} = $_[1] },
		 'verbose+' => \$ENV{VERBOSE_SERVER},
		);

    if ( !$stat || $help ) {
      print "Usage: ...\n";
      exit($stat == 0);
    }

    if ( defined($ENV{HTTP_SOAPACTION}) && !defined($ENV{CONTENT_TYPE}) ) {
      $ENV{CONTENT_TYPE} = 'text/xml';
    }

  }
}

####################################################################
# Constructor and getter/setter methods
####################################################################

########################################################################

# How to die gracefully within SOAP.
sub soap_die_handler {
  my ($string) = @_;

  my $d =
    document
      (element("SOAP-ENV:Envelope",
	       namespace("SOAP-ENV",$SOAP_ENV),
	       namespace("SOAP-ENC",$SOAP_ENC),
	       namespace("xsi",$xsi),
	       namespace("xsd",$xsd),
	       namespace("wsse",$wsse),
	       element("SOAP-ENV:Body",
		       element("SOAP-ENV:Fault",
			       element("faultcode",text("SOAP-ENV:Server")),
			       element("faultstring",text($string))
			      ))
	      ));

  print header(-status=>'500 Internal Server Error',
	       -type=>'text/xml',
	       -charset=>'utf-8');
  xml_to_fh($d,\*STDOUT);

  exit 0;
}


sub html_die_handler {
  my ($string) = @_;

  print h2("Server Error!"),p;
  print pre($string),p;
  exit 0;
}


####################################################################
# Go! Figure out the environment in which we are running. The options
# are,
#
# - SOAP request
# - POST
# - GET
# - GET?wsdl
# - run from the command line for debugging
####################################################################

sub go {
  my ($self) = @_;

  $self->_print(1,"Go!\n");

  $self->_ensure_interface();

  defined($self->{urn}) || assert(0,"Server URN not set.");
  defined($self->{name}) || assert(0,"Server name not set.");

  my $request_method = $ENV{REQUEST_METHOD} || 0;
  my $soapaction = $ENV{HTTP_SOAPACTION} || 0;
  my $content_type = $ENV{CONTENT_TYPE} || 0;
  my $query_string = $ENV{QUERY_STRING} || 0;


  my $result;
  # Determine how the request should be handled.
  if ( $soapaction || $content_type =~ 'application/soap\+xml' ) {
    # if the SOAPAction: header appears or the Content-type is
    # application/soap+xml, then it process it as a soap request, not
    # matter what the request method was.
    $result = $self->handle_soap($content_type =~ 'text/xml');
  } else {
    # use the request method to decide how to handle it.
    if ( $request_method eq "POST" ) {
      # POST method
      $result = $self->handle_post();
    } elsif ( $request_method eq "GET" ) {
      # GET method. Use the query string to decide how to handle.
      if ( lc($query_string) eq "wsdl" ) {
	$result = $self->handle_wsdl();
      } else {
	$result = $self->handle_get();
      }
    } else {
      # No request method? The script must be being called interactively
      # for debugging purposes. Handle it as SOAP.
      $result = $self->handle_soap(0);
    }
  }

  return $result;

}

########################################################################

sub handle_soap {
  my ($self,$content_type_is_text_xml) = @_;

  # Set the handler for die calls.
  $SIG{__DIE__} = \&soap_die_handler;

  my $server_urn = $self->{urn};
  defined($server_urn) || assert(0,"No server URN");
  my $server_name = $self->{name};
  defined($server_name) || assert(0,"No server name");

  # Read the request from STDIN
  my $request = xml_from_fh(\*STDIN);
  defined($request) || assert(0,"Can't parse request?!?");

  # Take a SOAP request. Parse it and extract the method name and
  # arguments. Call the appropriate function for the method. Package the
  # results into a SOAP response and return it.

  # Here we verify the digital signature if the server wants to check
  # digital signatures
  if (defined($self->{dsig})) { verify_envelope($self,$request); }

  #### DECRYPTION HERE #########
  if (defined($self->{enc})) { decrypt_body($self,$request); }

  my $envelope = xml_get_child($request,$SOAP_ENV,'Envelope');
  assert(defined($envelope));
  my $body = xml_get_child($envelope,$SOAP_ENV,'Body');
  assert(defined($body));

  # The body contains a single element which is the message.
  my @children = xml_get_children($body);
  $#children == 0 ||
    assert(0,"Error! file \"".__FILE__."\", line ".__LINE__);
  my $message = $children[0];

  # The method name is the node name of the message.
  my ($method_urn,$method_name) = xml_get_name($message);
  # The method name must appear in the right namespace.
  ($method_urn eq $server_urn) ||
    assert(0,"Method name not in the server namespace");

  # The method arguments are the children of the message.
  my %request_args = ();
  foreach my $arg ( xml_get_children($message) ) {
    my ($arg_ns,$arg_name) = xml_get_name($arg);
    # The arg name must appear in the right namespace.
    ($arg_ns eq $server_urn) ||
      assert(0,"Arg name not in the server namespace");

    $request_args{$arg_name} = $arg;
  }

  # %response_args = call $method_name with %request_args;
  my %response_args = $self->_dispatch_method($method_name, %request_args);

  # Put the response arguments together in a list.
  my @response_args_list = ();
  foreach my $k (keys %response_args) {
    push @response_args_list, $response_args{$k};
  }

  # Put together $method_name."Response" with %responses;
  my $response = 
    document(element("SOAP-ENV:Envelope",
		     namespace("SOAP-ENV",$SOAP_ENV),
		     namespace("SOAP-ENC",$SOAP_ENC),
		     namespace("xsi",$xsi),
		     namespace("xsd",$xsd),
		     namespace("server",$server_urn),
		     element("SOAP-ENV:Header"),
		     element("SOAP-ENV:Body",
			     element("server:".$method_name."Result",
				     @response_args_list))));

  # fixme: encrypt if need be

  # Use whatever content type that this client used.
  my $type;
  if ( $content_type_is_text_xml ) {
    # .NET requires this,...
    $type = 'text/xml';
  } else {
    # but SOAP 1.2 requires this,
    $type = 'application/soap+xml';
  }
    $type = 'text/xml';
  print header(-type=>$type,
 	       -charset=>'utf-8');
  xml_to_fh($response,\*STDOUT);

  return 0;
}

########################################################################

sub handle_post {
  my ($self) = @_;

  # Set the handler for die calls.
  $SIG{__DIE__} = \&html_die_handler;

  my $server_urn = $self->{urn};
  defined($server_urn) || assert(0,"No server URN");
  my $server_name = $self->{name};
  defined($server_name) || assert(0,"No server name");

  my $method_name = param("_method_");

  print header,
    start_html($server_name.": Results"),
      h1($server_name.": Results"), p;

  if (!param()) {
    print "No params? How did you manage that?", hr;
    print end_html;
    return 1;
  }

  # Throw an error if either dsig or enc was expected.
  if (defined($self->{dsig})) { 
    assert(0,"No digitial signatures for POST's");
  }
  if (defined($self->{enc})) { 
    assert(0,"No encryption for POST's");
  }

  # Determine the formal parameters based on the method name
  my @formal_params;
  if ( $method_name eq "Call" || $method_name eq "Spawn" ) {
    my %h = ();
    foreach my $p ( @{$self->{params}} ) {
      $h{$$p{name}} = $p;
    }
    foreach my $n ( @{$self->{in_order}} ) {
      my $p = $h{$n};
      assert(defined($p));
      if ( $$p{direc} eq "out" ) { 
	# nothing
      } else {
	push @formal_params, $p;
      }
    }
  } elsif ( $method_name eq "Running" || $method_name eq "Results" ) {
    @formal_params = ({ name=> 'uid', 
			direc=> 'in', 
			mech=> 'val',
			type=> 'string',
		      });
  } else {
    die;
  }

  # Parse the actual parameters.

  my %request_args = ();
  foreach my $p ( @formal_params ) {
    my $name = $$p{name};
    assert(defined($p),"No value for $name");
    my $mech = $$p{mech};
    my $type = $$p{type};
    my $value;
    if ( $mech eq 'val' ) {
      $value = param($name);
    } elsif ( $mech eq 'file' ) {
      my $fh = param($name);	#upload($name);
      assert($fh,"File $name is missing");
      $value = '';
      # deleteme
      #print pre("+".$fh."\n"),p;
      while (<$fh>) {
	# deleteme
	#print pre("*\n"),p;
	$value .= $_;
      }
    } else {
      assert(0);
    }
    if ( $value ne '') {
      $request_args{$name} = $value;
    }
  }

  print "Invoking method $method_name. Please wait.",p;
  # %response_args = call $method_name with %request_args;
  my %response_args = $self->_dispatch_method($method_name, %request_args);
  print "Done.",p;

  # print the results
  foreach my $k ( keys %response_args ) {
    print h2($k,":"),hr;
    my $value = $response_args{$k};
    # evil hack : fixme
    my $env = { xsi => "$xsi", xsd => "$xsd" };
    $$value[1] = $env;
    print pre(escape_HTML(arg_decode_to_string($value))),p;
    print hr;
  }

#   # Additional buttons for some methods
#   if ($method_name eq "Spawn") {
#     print start_form;
#     print hidden('_method_','Running');
#     print hidden('uid',arg_decode_to_string($response_args{uid}));
#     print submit('Running');
#     print end_form;
#   } elsif ($method_name eq "Running") {
#   }
#   print hr;

  print end_html;

  return 0;
}



########################################################################

# Generate WSDL for the server.
# ....
sub handle_wsdl {
  my ($self) = @_;

  # Set the handler for die calls.
  $SIG{__DIE__} = \&html_die_handler;

  my $server_name = $self->{name};
  defined($server_name) || assert(0,"No server name");

  # the service element

  my $location;
  if (!defined($ENV{SERVER_PROTOCOL})) {
    assert(0,"Undefined protocol");
  } elsif ($ENV{SERVER_PROTOCOL} =~ "^HTTP/1.") {
    $location = sprintf("http://%s%s",
			$ENV{HTTP_HOST},
			$ENV{REQUEST_URI});
  } elsif ($ENV{SERVER_PROTOCOL} eq "CGIFILE") {
    $location = sprintf("cgifile:%s", $ENV{REQUEST_URI});
  } else {
    assert(0,"What kind of SERVER_PROTOCOL is ".$ENV{SERVER_PROTOCOL});
  }

  $location =~ s/\?wsdl$//;

  my $port_name = $server_name."Port";
  my $service_name = $server_name."Service";

  # Generate the WSDL
  my $d = $self->_wsdl_generate
    (sub {
       my ($binding_name) = @_;
       my $service =
	 element("service",
		 attr("name",$server_name),
		 element("documentation",
			 text("WSDL File for ".$server_name)),
		 element("port",
			 attr("name",$port_name),
			 attr("binding","server:".$binding_name),
			 element("soap:address",
				 attr("location",$location))));
       return $service;
     });

  # Print it.
  print header(-type=>'text/xml',
   	       -charset=>'utf-8');
  xml_to_fh($d,\*STDOUT);

  # Done!

  return 0;
}

########################################################################

sub handle_get {
  my ($self) = @_;

  # Set the handler for die calls.
  $SIG{__DIE__} = \&html_die_handler;

  my $server_urn = $self->{urn};
  defined($server_urn) || assert(0,"No server URN");
  my $server_name = $self->{name};
  defined($server_name) || assert(0,"No server name");

  my $method_name = $ENV{QUERY_STRING};

  if (!defined($method_name) || $method_name eq "") {
    print header,"\n";
    print start_html($server_name),"\n";
    print h1($server_name),"\n";

    my $script_name = basename($ENV{SCRIPT_NAME});
    assert(defined($script_name));

    print h2('Methods'),"\n";
    foreach my $method ("Call","Spawn","Running","Results") {
      print a({-href=>$script_name."?".$method},$method),p,"\n";
    }

    print h2('Interface'),"\n";
    print a({-href=>$script_name."?wsdl"},"WSDL"),p,"\n";

    print hr,"\n";
    print end_html,"\n";
  } else {
    print header,"\n";
    print start_html($server_name.":$method_name"),"\n";
    print h1($server_name.":$method_name"),"\n";

    # Chose the input parameters for the method
    my @params;
    if ( $method_name eq "Call" || $method_name eq "Spawn" ) {
      my %h = ();
      foreach my $p ( @{$self->{params}} ) {
	$h{$$p{name}} = $p;
      }
      foreach my $n ( @{$self->{in_order}} ) {
	my $p = $h{$n};
	assert(defined($p));
	if ( $$p{direc} eq "out" ) { 
	  # nothing
	} else {
	  push @params, $p;
	}
      }
    } elsif ( $method_name eq "Running" || $method_name eq "Results" ) {
      @params = ({ name=> 'uid', 
		   direc=> 'in', 
		   mech=> 'val',
		   type=> 'string',
		 });
    } else {
      die;
    }

    # Generate the form
    print start_multipart_form,"\n";
    print hidden('_method_',$method_name),"\n";
    foreach my $p ( @params ) {
      my $name = $$p{name};
      my $direc = $$p{direc};
      my $mech = $$p{mech};
      my $type = $$p{type};
      my $optional = $$p{optional};
      my $default = $$p{default};
      print $name, "[", $type, "]:";
      if ( $type eq "xml" || $type eq "raw" ) {
	print filefield(-name=>$name);
      } else {
	print textfield($name);
      }
      print p,"\n";

    }
    print submit, end_form, "\n";
    print hr,"\n";
    print end_html,"\n";
  }
  return 0;
}

########################################################################

1;
