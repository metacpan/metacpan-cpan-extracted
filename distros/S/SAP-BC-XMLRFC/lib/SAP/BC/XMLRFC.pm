package SAP::BC::XMLRFC;


use strict;

use SAP::BC;
use SAP::BC::Iface;
use HTTP::Request;
use HTTP::Cookies;
use LWP::UserAgent;
use XML::Parser;


use Data::Dumper;



use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;


@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT_OK = qw (
  Iface
  xmlrfc
);

# Global debug flag

my $DEBUG = undef;

# Valid parameters
my $VALID = {
   SERVER => 1,
   BC => 1,
   USERID => 1,
   PASSWD => 1
};

my $_out = "";
my $_cell = "";
my $_tagre = "";

$VERSION = '0.06';

# Preloaded methods go here.


sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {
     @_
  };

  die "Server not supplied !" if ! exists $self->{SERVER};
  die "SAP BC USERID not supplied !" if ! exists $self->{USERID};
  die "SAP BC Password not supplied (PASSWD) !" if ! exists $self->{PASSWD};

# Validate parameters
  map { delete $self->{$_} if ! exists $VALID->{$_} } keys %{$self};

# check that the service exists
  $self->{BC} = new SAP::BC( 
                             server => $self->{SERVER},
                             user   => $self->{USERID},
			     password => $self->{PASSWD}
			     );
# create the object and return it
  bless ($self, $class);
  return $self;
}


# method to dynamically create functions SAP::BC::Iface
sub Iface{

  my $self = shift;
  my $service = shift;
  die "No Service name supplied to lookup " if ! $service;
  die "Service does not exist - $service " if ! exists $self->{BC}->services->{$service};
  my $lookup = "/invoke/sap.rfc/createTemplate";

  $self->{BC}->_prime_ua();
  my $ua = $self->{BC}->{ua};

#  print STDERR "REQ: ".$self->{SERVER}.$lookup."\?\$call\=true\&serverName\=".
#      $self->{BC}->services->{$service}->{sapsys}.
#	  "\&\$rfcname\_search\=\&groupname=\&\$rfcname\=".
#	      $self->{BC}->services->{$service}->{rfcname}.
#		  "\&table=\&submit\=RFC\-XML" ."\n";
  my $req = new HTTP::Request('GET', $self->{SERVER}.$lookup."\?\$call\=true\&serverName\=".
      $self->{BC}->services->{$service}->{sapsys}.
	  "\&\$rfcname\_search\=\&groupname=\&\$rfcname\=".
	      $self->{BC}->services->{$service}->{rfcname}.
		  "\&table=\&submit\=RFC\-XML" );

  $req->authorization_basic($self->{USERID},$self->{PASSWD});

  my $res = $ua->request($req);

  die " Interface lookup call failed: " . $res->message() if !$res->is_success();

  my $content = $res->content;
  die "RFC_SYSTEM_FAILURE in interface lookup" if $content =~ /RFC_ERROR/s;
  my ( $xml_template ) = 
      $content =~ /^.*xmlData<\/B><\/TD>\s*<TD>(.*?)<\/TD>.*$/s;

  my $p = new XML::Parser( Style => 'Tree',
			 ErrorContext => 3 );

  my $r =  $p->parse( $xml_template );

  my $intrfc = $self->{BC}->services->{$service}->{rfcname};
  $intrfc =~ s/\//\_\-/g;
  die "Interface lookup failed for $service " unless
      $r->[1]->[8]->[3] eq "rfc:".$intrfc;  

  my $iface = new SAP::BC::Iface( NAME => $service );

#  shift over to the interface definition part of the doc
  $r = $r->[1]->[8]->[4]; 
  my $c = -1;
  while (my $parmname = $r->[$c+=4]){
#      print STDERR " Parm: $parmname \n";
      my $parm = $r->[$c + 1];
# determine a table or structure or simple parameter
      if ( $parm->[3] =~ /\w/){
# we have either a structure or a table
	  if ( $parm->[3] =~ /item/ ){
# we have a table
	      my $struct = SAP::BC::Struc->new( NAME => $parmname );
# add fields
	      my $d = -1;
	      while ( my $fieldname = $parm->[4]->[$d+=4] ){
#  fudge for a bad last one ?
		  next unless $fieldname =~ /\w/;
		  $struct->addField( NAME => $fieldname,
				     TYPE => 'chars' );
	      };
	      $iface->addTab( NAME => $parmname,
			  STRUCTURE => $struct );
	  } else  {
# we have a structure
	      my $struct = SAP::BC::Struc->new( NAME => $parmname );
	      my $d = -1;
	      while ( my $fieldname = $parm->[$d+=4] ){
#  fudge for a bad last one ?
		  next unless $fieldname =~ /\w/;
		  $struct->addField( NAME => $fieldname,
				     TYPE => 'chars' );
	      };
	      $iface->addParm( NAME => $parmname,
			       TYPE => 'chars',
			       STRUCTURE => $struct );
	  };
      } else {
	  $iface->addParm( NAME => $parmname,
			   TYPE => 'chars' );
      };
  };

#  print STDERR "Iface: ".Dumper($iface);
  return $iface;

}


# Call The Function module
sub xmlrfc {
  my $xml_out = "";
  my $intrfc = "";
  my $self = shift;
  my $iface = shift;
  my $ref = ref($iface);
  die "this is not an Interface Object!" 
     unless $ref eq "SAP::BC::Iface" and $ref;

  $self->{BC}->_prime_ua();
  my $ua = $self->{BC}->{ua};

  my $service = $iface->name();
#  print STDERR "The services- $service -: ".Dumper( $self->{BC}->services);
  $intrfc = $self->{BC}->services->{$service}->{rfcname};
  $intrfc =~ s/\//\_\-/g;
  $service =~ s/\:/\//;
  my $req = new HTTP::Request('POST', $self->{SERVER}."/invoke/".$service);
  $req->header('Content-Type' => 'application/x-sap.rfc');
	       #'Host' => 'my.source.host.net');

  $req->authorization_basic($self->{USERID},$self->{PASSWD});

  my $start_content = <<ENDOFSTART;
<?xml version="1.0" encoding="iso-8859-1"?>
<sap:Envelope xmlns:sap="urn:sap-com:document:sap" version="1.0">
  <sap:Header xmlns:rfcprop="urn:sap-com:document:sap:rfc:properties">
      <saptr:From xmlns:saptr="urn:sap-com:document:sap:transport">BC1</saptr:From>
      <saptr:To xmlns:saptr="urn:sap-com:document:sap:transport">BC2</saptr:To>
  </sap:Header>
  <sap:Body>
ENDOFSTART

    my $end_content = <<ENDOFEND;
  </sap:Body>
</sap:Envelope>
ENDOFEND

  $xml_out = "<rfc:".$intrfc.
      " xmlns:rfc=\"urn:sap-com:document:sap:rfc:functions\">\n";

  map{ 
      $xml_out.= "   <" . $_->name .">";
      if (my $s = $_->structure ){
	  $xml_out.= "\n";
	  map {  $xml_out.= "     <" . $_ .">" . $s->Fieldvalue($_) .
		     "<\/" . $_ . ">\n" ;
	     } ( $s->Fields );
	  $xml_out.= "    <\/" . $_->name . ">\n" ;
      } else {
	  $xml_out.= $_->value . "<\/" . $_->name . ">\n" ;
      };
  } ( $iface->Parms );
  map{ my $tab = $_;
       $xml_out.= "   <" . $tab->name . ">\n";
       while ( my $row = $tab->nextrow ){
	   $xml_out .= "     <item>\n"; 
	   map {  $xml_out .= "     <$_>$row->{$_}<\/$_>\n" } keys %{$row};
	   $xml_out .= "    <\/item>\n"; 
       }; 
#       map {  $xml_out .= "      <" . $_ . ">" . "<\/" . $_ . ">\n";
#       } ( $tab->structure->Fields );
       $xml_out.= "   <\/" . $tab->name . ">\n" 
       } ( $iface->Tabs );

  $xml_out .= "<\/rfc:".$intrfc.">\n";
#  print STDERR "the constructed interface: ".$start_content.$xml_out.$end_content;

  $req->content($start_content.$xml_out.$end_content); 

  my $res = $ua->request($req);

  die " RFC-XML call failed: " . $res->as_string() if !$res->is_success();

  $xml_out = $res->content;
#  print $xml_out;
  die "RFC_SYSTEM_FAILURE in interface lookup".$xml_out if $xml_out =~ /RFC_ERROR/s;

  my $p = new XML::Parser( Style => 'Tree',
			 ErrorContext => 3
			   );

# pick properly handled RFC errors
  my ($faultcode, $faultstring, $faultname) = 
      $xml_out =~ /^.*?\<faultcode\>(.*?)\<\/faultcode\>.*?
	  \<faultstring\>(.*?)\<\/faultstring\>.*?
	      \<name\>(.*?)\<\/name\>.*$/sx;
  die "RFX-XML call error: ".$faultcode." ".$faultstring." ".$faultname if $faultcode;

  my $r =  $p->parse( $xml_out );

  $r = $r->[1]->[4]->[4];
  my $c = -1;
  while (my $parmname = $r->[$c+=4]){
      my $parm = $r->[$c + 1];
# is this a table ?
      if ( $parm->[3] eq 'item' ){
	  $iface->Tab($parmname)->empty;
# process each row
	  my $i = -1;
	  while ($parm->[$i+=4] eq 'item'){
# process each field
	      my $row = $parm->[$i + 1];
	      my @row = ();
	      my $j = -1;
	      while ( my $field = $row->[$j+=4] ){
		  push( @row, $row->[$j + 1]->[2] );
	      };
	      $iface->Tab($parmname)->addrow(\@row);
	  };
      } else {
# is it a complex parameter
	  $iface->addParm( SAP::BC::Parms->new( NAME => $parmname,
					       TYPE => 'chars') );
	  if ( $parm->[3] =~ /\w/ ){
	      my $struct = SAP::BC::Struc->new( NAME => $parmname );
	      my $d = -1;
	      while ( my $fieldname = $parm->[$d+=4] ){
#  fudge for a bad last one ?
		  next unless $fieldname =~ /\w/;
		  my $field = $parm->[$d + 1];
		  $struct->addField( NAME => $fieldname,
				     TYPE => 'chars',
				     VALUE => $field->[2]);
	      };
	      $iface->Parm($parmname)->structure( $struct );
	  } else {
# Simple Parameter
	      $iface->Parm($parmname)->value($parm->[2]);
	  };
      };
  };
}

sub disconnect {
  my $self = shift;
  $self->{'BC'}->disconnect();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SAP::BC::XMLRFC - Perl extension for performing RFC Function calls against an SAP R/3 using the Business Connector System.  Please refer to the README file found with this distribution.

=head1 SYNOPSIS

#  Setup up a service in the SAP BC server for an RFC-XML based call to RFC_READ_REPORT
#   called test:ReadReport to make this example work

  use SAP::BC::XMLRFC;
  $rfc = new SAP::BC::XMLRFC( );

  my $userid = 'testuser';
  my $passwd = 'letmein';
  my $server="http://my.server.blah:5555";
  my $service = 'test:ReadReport';

# build the connecting object
  my $xmlrfc = new SAP::BC::XMLRFC( SERVER => $server,
				    USERID => $userid,
				    PASSWD => $passwd );
#  Discover the interface definition for a function module
  my $i = $xmlrfc->Iface( $service );

#  set a parameter value of the interface
  $i->Parm('PROGRAM')->value('SAPLGRAP');

# call the BC service with an interface object
  $xmlrfc->xmlrfc( $i );

  print "Name:", $i->Parm('TRDIR')->structure->NAME, "\n";
  map {print @{$_}, "\n"  } ( $i->Tab('QTAB')->rows );

  while ( my $row = $i->Tab('QTAB')->nextrow ){
      map { print "$_ = $row->{$_} \n" } keys %{$row};
  };


=head1 DESCRIPTION

Enabler for XMLRFC calls to SAP vi athe SAP Business Connector

=head1 METHODS:

	my $rfc = new SAP::BC::XMLRFC( SERVER => $server,
				       USERID => $userid,
				       PASSWD => $passwd );


=head1 AUTHOR

Piers Harding, saprfc@kogut.demon.co.uk.

But Credit must go to all those that have helped.


=head1 SEE ALSO

perl(1), SAP::BC(3), SAP::BC::XMLRFC(3), SAP::BC::Iface(3)

=cut

1;
