# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

########################################################################
# Some internal routines
########################################################################

package SOAP::Clean::Internal;

use strict;
use warnings;

use File::Temp qw/ :POSIX /;
use MIME::Base64;
use Data::Dumper;

use SOAP::Clean::Misc;
use SOAP::Clean::XML;

BEGIN {
  use Exporter   ();
  our (@ISA, @EXPORT);

  @ISA         = qw(Exporter);
  @EXPORT      = qw(
 		    &arg_decode_to_xml
 		    &arg_decode_to_string
		    &arg_encode
 		    &arg_encode_raw
 		    &arg_encode_bool
 		    &arg_encode_float
 		    &arg_encode_int
 		    &arg_encode_string
 		    &arg_encode_url
 		    &arg_encode_xml
 		    &arg_strip_white
		    &is_type

		    $SOAP_ENC
		    $SOAP_ENV
		    $soaphttp
		    $ds
		    $wsdl
		    $wsdl_http
		    $wsdl_mime
		    $wsdl_soap
		    $wsse
		    $xenc
		    $xsd
		    $xsi
		   );

}

########################################################################
# Global variable initialization
########################################################################

# initialize package globals, first exported ones

our $SOAP_ENC = "http://schemas.xmlsoap.org/soap/encoding/";
our $SOAP_ENV = "http://schemas.xmlsoap.org/soap/envelope/";
our $soaphttp = "http://schemas.xmlsoap.org/soap/http";
our $ds = "http://www.w3.org/2000/09/xmldsig#";
our $wsdl = "http://schemas.xmlsoap.org/wsdl/";
our $wsdl_http = "http://schemas.xmlsoap.org/wsdl/http/";
our $wsdl_mime = "http://schemas.xmlsoap.org/wsdl/mime/";
our $wsdl_soap = "http://schemas.xmlsoap.org/wsdl/soap/";
our $wsse = "http://schemas.xmlsoap.org/ws/2002/04/secext";
our $xenc = "http://www.w3.org/2001/04/xmlenc#";
our $xsd = "http://www.w3.org/2001/XMLSchema";
our $xsi = "http://www.w3.org/2001/XMLSchema-instance";


# non-exported package globals go here
# our $var = "...";

########################################################################

sub arg_encode {
  my ($type,$name,$value) = @_;

  if ( $type eq 'bool' ) {
    return arg_encode_bool($name,$value);
  } elsif ( $type eq 'int' ) {
    return arg_encode_int($name,$value);
  } elsif ( $type eq 'float' ) {
    return arg_encode_float($name,$value);
  } elsif ( $type eq 'string' ) {
    return arg_encode_string($name,$value);
  } elsif ( $type eq 'raw' ) {
    return arg_encode_raw($name,$value);
  } elsif ( $type eq 'xml' ) {
    return arg_encode_xml($name,$value);
  } else {
    assert(0,"Can't deal with type ".$type);
  }
}

sub arg_encode_bool {
  my ($name,$val) = @_;
  return element($name,
		 attr("xsi:type","xsd:boolean"),
		 text($val ? "true" : "false"));
}

sub arg_encode_float {
  my ($name,$val) = @_;
  return element($name,
		 attr("xsi:type","xsd:float"),
		 text($val));
}

sub arg_encode_int {
  my ($name,$val) = @_;
  return element($name,
		 attr("xsi:type","xsd:int"),
		 text($val));
}

sub arg_encode_string {
  my ($name,$val) = @_;
  return element($name,
		 attr("xsi:type","xsd:string"),
		 text($val));
}

sub arg_encode_url {
  my ($name,$val) = @_;
  return element($name,
		 attr("xsi:type","xsd:anyURI"),
		 text($val));
}

sub arg_encode_raw {
  my ($name,$val) = @_;
  return element($name,
		 attr("xsi:type","xsd:base64Binary"),
		 text(encode_base64($val)));
}

sub arg_encode_xml {
  my ($name,$val) = @_;
  if (!ref($val)) {
    # It's a string. Parse it.
    $val = xml_from_string($val);
  }
  if (xml_is_document($val)) {
    ($val) = xml_get_children($val);
  }
  # fixme: Make sure that any surrounding default namespaces do
  # not capture unqualified attributes in the raw XML.
  return element($name, $val);
}

########################################################################

# does $n have type ($target_url,$target_local)?
sub is_type {
  my ($target_url,$target_local,$n) = @_;
  my $type = xml_get_attr($n,$xsi,"type");
  if ( !defined($type) ) { return 0; }
  return xml_same_names($target_url,$target_local,
		       xml_fix_name($n,$type));
}


sub arg_strip_white {
  my ($s) = @_;
  $s =~ s/[\n\t]/ /g;
  $s =~ s/ +/ /g;
  $s =~ s/^ +//;
  $s =~ s/ +$//;
  return $s;
}

sub arg_decode_to_string {
  my ($n) = @_;
  if (!(ref $n)) {
    # It's already a "string"
    return $n;
  } elsif (is_type($xsd,"boolean",$n)) {
    my $result = arg_strip_white(xml_get_text($n));
    chomp($result);
    return 1 if ( $result eq "true" );
    return 0 if ( $result eq "false" );
    assert(0,"\"".$result."\" is not a valid boolean value");
  } elsif (is_type($xsd,"float",$n)) {
    my $result = arg_strip_white(xml_get_text($n));
    chomp($result);
    return $result;
  } elsif (is_type($xsd,"int",$n)) {
    my $result = arg_strip_white(xml_get_text($n));
    chomp($result);
    return $result;
  } elsif (is_type($xsd,"string",$n)) {
    return xml_get_text($n);
  } elsif (is_type($xsd,"anyURI",$n)) {
    my $result = arg_strip_white(xml_get_text($n));
    chomp($result);
    return $result;
  } elsif (is_type($xsd,"base64Binary",$n)) {
    return decode_base64(xml_get_text($n));
  } else {
    my @kids = xml_get_children($n);
    if ( $#kids == 0 ) {
      # If this argument element one element children, then decode the
      # child as unparsed XML.
      return xml_to_string(arg_decode_to_xml($n));
    } elsif ( $#kids == -1 )  {
      # Otherwise, the argument element has no element children then
      # it had better have text children!
      return xml_get_text($n);
    } else {
      # Ack! Multiple children elements?! How are we suppose to handle
      # that?!
      assert(0,"Cannot convert multiple children element to a string.");
    }
  }
}

sub arg_decode_to_xml {
  my ($n) = @_;
  if (!(ref $n)) {
    # It's already a "string"
    return xml_from_string($n);
  } elsif (is_type($xsd,"string",$n)) {
    return xml_from_string(xml_get_text($n));
  } elsif (is_type($xsd,"base64Binary",$n)) {
    return xml_from_string(decode_base64(xml_get_text($n)));
  } else {
    # Some arbitrary XML element.
    my @kids = xml_get_children($n);
    if ( $#kids != 0 ) {
      assert(0,"Argument value is not an xml element: ".Dumper($n));
    }
    return xml_extract_and_close_child($kids[0]);
}
}

########################################################################

package SOAP::Clean::Internal::Actor;

use SOAP::Clean::Misc;

# Inheritance
our @ISA = qw(SOAP::Clean::Misc::Object);

sub initialize {
  my ($self) = @_;
  $self->{is_server} = 0;
  $self->{verbose} = 0;
  $self->{request_count} = 0;
  $self->{response_count} = 0;
}

sub counts {
  my ($self) = @_;
  return ($self->{request_count},$self->{response_count});
}

sub verbose {
  my ($self,$verbose_level) = @_;
  $self->{verbose} = $verbose_level;
  return $self;
}

sub dsig_keys{
  my ($self,$dsigcl,$key_file,$cert_file,$tmpl_file,$appl) = @_;
  $self->{dsig} = $dsigcl;
  $self->{key} = $key_file;
  $self->{cert} = $cert_file;
  $self->{tmpl} = $tmpl_file;
  $self->{appl} = $appl;
  return $self;
}       

sub enc_dec_params{
  my ($self,$enccl,$privkey_file_enc,$pubkey_file_enc,$tmpl_file,$appl) = @_;
  $self->{enc} = $enccl;
  $self->{privkeyenc} = $privkey_file_enc;
  $self->{pubkeyenc} = $pubkey_file_enc;
  $self->{enctmpl} = $tmpl_file;
  $self->{appl} = $appl;
  return $self;
}       

sub _print {
  my $self = shift;
  my $level = shift;

  if ( $self->{verbose} > $level ) {
    print(@_);
  }
}

# Do the web communication
sub _comm {
  my ($self,$tag, $server_url,$request_method,$request_headers,$request_str) 
    = @_;

  # Set up the request
  my $ua = LWP::UserAgent->new;
  my $request = HTTP::Request->new($request_method => $server_url);
  if (defined($request_headers)) {
    foreach my $k ( keys %$request_headers ) {
      $request->header($k,$$request_headers{$k});
    }
  }
  if (defined($request_str) && $request_str) {
    $request->content($request_str);
  }

  # Messages and statistics before sending
  if ( $self->{verbose} ) {
    $self->_print(1,"##################################################\n");
    if ($tag) {
      $self->_print(0,"Invoking ",$tag," at ",$server_url,"...\n");
    } else {
      $self->_print(0,"Invoking ",$server_url,"...\n");
    }
    my $request_str = $request->as_string();
    $self->_print(1,$request_str);
    $self->{request_count} += length($request_str);
  }

  # Send the request - receive the response.
  my $response = $ua->request($request);

  # Messages and statistics after receiving
  if ( $self->{verbose} ) {
    $self->_print(1,"##################################################\n");
    $self->_print(1,,"Response:\n");
    my $response_str = $response->as_string();
    $self->_print(1,$response_str);
    $self->_print(1,"##################################################\n");
    $self->{response_count} += length($response_str);
  }

  return $response;
}

########################################################################

END { }				# module clean-up code here (global destructor)


