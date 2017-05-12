package SAP::WAS::SOAP;


use strict;

use SAP::WAS::Iface;
use SOAP::Lite;


my $sr = "";
my $namespace = "rfc:";
my $muri = "urn:sap-com:document:sap:rfc:functions";
my $s = new SOAP::Lite->uri( $muri );
$s->encoding('ISO-8859-1');

import SOAP::Data 'name';



use Data::Dumper;



use vars qw($VERSION $AUTOLOAD);

# Global debug flag
my $DEBUG = undef;

# Valid parameters
my $VALID = {
   URL => 1,
   USERID => 1,
   PASSWD => 1
};

my $_out = "";
my $_cell = "";
my $_tagre = "";

$VERSION = '0.05';

# Preloaded methods go here.


sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {
     @_
  };

  die "SOAP URL not supplied !" if ! exists $self->{URL};
  die "SAP WAS USERID not supplied !" if ! exists $self->{USERID};
  die "SAP WAS Password not supplied (PASSWD) !" if ! exists $self->{PASSWD};

# Validate parameters
  map { delete $self->{$_} if ! exists $VALID->{$_} } keys %{$self};

# check that the service exists
#  $self->{WAS} = new SAP::WAS( 
#                             server => $self->{SERVER},
#                             user   => $self->{USERID},
#			     password => $self->{PASSWD}
#			     );

# Fix credentials as supplied by Christian Wippermann
eval '
sub SOAP::Transport::HTTP::Client::get_basic_credentials {
	 #warn "credentials $self->{USERID} => $self->{PASSWD} \n";
   return "$self->{USERID}" => "$self->{PASSWD}";
}
';
# create the object and return it
  bless ($self, $class);
  return $self;
}


# method to return a structure object of SAP::Structure type
sub structure {

  my $self = shift;
  my $struct = shift;
  #my $info = $self->sapinfo();

  my @parms = (name('TABNAME'=> $struct), name('FIELDS'));
  my $methname = "RFC_GET_STRUCTURE_DEFINITION_P";
  #my $meth =  'rfc:'.$methname;
  my $meth =  $methname;
  my $element =  $methname.'.Response';
  #$sr = $s->serializer->autotype(0)->readable(1)->method( $namespace.$methname => @parms );
  $sr = $s->serializer->autotype(0)->readable(1)->method( $methname => @parms );
  #print "$methname SOAP: $sr\n";
  my $som =  $s->uri($muri)->proxy($self->{'URL'})->$meth( @parms );
  my @res = $som->valueof("//Envelope/Body/$element/FIELDS/item");


  $struct = SAP::WAS::Struc->new( NAME => $struct );

  foreach my $field ( @res ){
    $struct->addField( NAME => $field->{'FIELDNAME'},
        	       TYPE => 'chars' );
  }

  return $struct;

}


# method to dynamically create functions SAP::WAS::Iface
sub Iface{

  my $self = shift;
  my $rfcname = shift;
  die "No RFC name supplied to lookup " if ! $rfcname;

  my $info = {};
  my @parms = (name( 'FUNCNAME' => $rfcname), name('PARAMS_P'));
  my $methname = "RFC_GET_FUNCTION_INTERFACE_P";
  #my $meth =  'rfc:'.$methname;
  my $meth =  $methname;
  my $element =  $methname.'.Response';
  #print "$methname SOAP: $sr\n";
  #$sr = $s->serializer->autotype(0)->readable(1)->method( $namespace.$methname => @parms );
  $sr = $s->serializer->autotype(0)->readable(1)->method( $methname => @parms );
  my $som =  $s->uri($muri)->proxy($self->{'URL'})->$meth( @parms );
  my @res = $som->valueof("//Envelope/Body/$element/PARAMS_P/item");
#  print STDERR "//Envelope/Body/$element/PARAMS_P \n".Dumper(\@res);

  my $iface = new SAP::WAS::Iface( NAME => $rfcname );

  foreach my $parm ( @res ){
      my $type = $parm->{'PARAMCLASS'};
      my $datatype = $parm->{'EXID'};
      my $default = $parm->{'DEFAULT'};
      my $text = $parm->{'PARAMTEXT'};
      my $name = $parm->{'PARAMETER'};
      my $tabname = $parm->{'TABNAME'};
      $tabname =~ s/\s//g;
      my $field = $parm->{'FIELDNAME'};
      $field =~ s/\s//g;
      my $intlen = $parm->{'INTLENGTH'};
      $intlen = int($intlen);
      my $decs = $parm->{'DECIMALS'};
      $decs = int($decs);
      my $pos = $parm->{'POSITION'};
      $pos = int($pos);
      my $off = $parm->{'OFFSET'};
      $off = int($off);
      # if the character value default is in quotes - remove quotes
      if ($defaul't =~ /^\'(.*?)\'\s*$/){
	  $default = $1;
	  # if the value is an SY- field - we have some of them in sapinfo
      } elsif ($default =~ /^SY\-(\w+)\W*$/) {
	  $default = 'RFC'.$1;
	  if ( exists $info->{$default} ) {
	      $default = $info->{$default};
	  } else {
	      $default = undef;
	  };
      };
      my $structure = "";
      if ($datatype eq "C"){
	  # Character
#	  $datatype = RFCTYPE_CHAR;
	  $default = " " if $default =~ /^SPACE\s*$/;
#	  print STDERR "SET $name TO $default \n";
      } elsif ($datatype eq "X"){
	  # Integer
#	  $datatype = RFCTYPE_BYTE;
	  $default = pack("H*", $default) if $default;
      } elsif ($datatype eq "I"){
	  # Integer
#	  $datatype = RFCTYPE_INT;
	  $default = int($default) if $default;
      } elsif ($datatype eq "s"){
	  # Short Integer
#	  $datatype = RFCTYPE_INT2;
	  $default = int($default) if $default;
      } elsif ($datatype eq "D"){
	  # Date
#	  $datatype = RFCTYPE_DATE;
	  $default = '00000000';
	  $intlen = 8;
      } elsif ($datatype eq "T"){
	  # Time
#	  $datatype = RFCTYPE_TIME;
	  $default = '000000';
	  $intlen = 6;
      } elsif ($datatype eq "P"){
	  # Binary Coded Decimal eg. CURR QUAN etc
#	  $datatype = RFCTYPE_BCD;
	  #$default = 0;
      } elsif ($datatype eq "N"){
	  #  Numchar
#	  $datatype = RFCTYPE_NUM;
	  #$default = 0;
	  $default = sprintf("%0".$intlen."d", $default) 
	      if $default == 0 || $default =~ /^[0-9]+$/;
      } elsif ($datatype eq "F"){
	  #  Float
#	  $datatype = RFCTYPE_FLOAT;
	  #$default = 0;
#      } elsif ( ($datatype eq " " or ! $datatype ) and $type ne "X"){
      } elsif ( ! $field and $type ne "X"){
	  # do a structure object
	  $structure = structure( $self, $tabname );
#	  $datatype = RFCTYPE_BYTE;
      } else {
	  # Character
#	  $datatype = RFCTYPE_CHAR;
	  $datatype = "C";
	  $default = " " if $default =~ /^SPACE\s*$/;
      };
#      $datatype = RFCTYPE_CHAR if ! $datatype;
      $datatype = "C" if ! $datatype;
      if ($type eq "I"){
	  #  Export Parameter - Reverse perspective
         $iface->addParm( NAME => $name,
			       PHASE => 'I',
			       TYPE => 'chars',
			       STRUCTURE => $structure );
#	  $interface->addParm( 
#			       TYPE => RFCEXPORT,
#			       INTYPE => $datatype, 
#			       NAME => $name, 
#			       STRUCTURE => $structure, 
#			       DEFAULT => $default,
#			       VALUE => $default,
#			       DECIMALS => $decs,
#			       LEN => $intlen);
      } elsif ( $type eq "E"){
	  #  Import Parameter - Reverse perspective
         $iface->addParm( NAME => $name,
			       PHASE => 'E',
			       TYPE => 'chars',
			       STRUCTURE => $structure );
#	  $interface->addParm( 
#			       TYPE => RFCIMPORT,
#			       INTYPE => $datatype, 
#			       NAME => $name, 
#			       STRUCTURE => $structure, 
#			       VALUE => undef,
#			       DECIMALS => $decs,
#			       LEN => $intlen);
      } elsif ( $type eq "T"){
	  #  Table
         $iface->addTab( NAME => $name,
			  STRUCTURE => $structure );
#	  $interface->addTab(
#			     # INTYPE => $datatype, 
#			     INTYPE => RFCTYPE_BYTE, 
#			     NAME => $name,
#			     STRUCTURE => $structure, 
#			     LEN => $intlen);
      } else {
	  # This is an exception definition
#	  $iface->addException( $name );
      };
  };


#  print STDERR "Iface: ".Dumper($iface);
  return $iface;

}


# Call The Function module
sub soaprfc {
  my $intrfc = "";
  my $self = shift;
  my $iface = shift;
  my $ref = ref($iface);
  die "this is not an Interface Object!" 
     unless $ref eq "SAP::WAS::Iface" and $ref;


  my $methname = $iface->name();
  #my $meth =  'rfc:'.$methname;
  my $meth =  $methname;
  my $element =  $methname.'.Response';

  #my @parms = ( name( 'FUNCNAME'=> $rfcname ) );
  my @parms = ();
  foreach my $p ( $iface->Parms ){
    next unless $p->phase() eq 'I';
    if (my $s = $p->structure ){
      my @fields  = ();
      foreach my $f ( $s->Fields ){
        push( @fields, \name( $f => $s->Fieldvalue($f) ) );
      }
      push( @parms, name( $p->name() => @fields ) );
    } else {
      push( @parms, name( $p->name() => $p->value() ) );
    }
  }
  
  foreach my $t ( $iface->Tabs ){
    my @items  = ();
    while ( my $row = $t->nextrow ){
      my @fields  = ();
      map {  push ( @fields, \name( $_ =>  $row->{$_} ) ) } keys %{$row};
      push( @items, \name( item => @fields ) );
    }; 
    push( @parms, name( $t->name() => @items ) );
  }

  #$sr = $s->serializer->autotype(0)->readable(1)->method( $namespace.$methname => @parms );
  $sr = $s->serializer->autotype(0)->readable(1)->method( $methname => @parms );
  #print "$methname SOAP: $sr\n";



  my $som =  $s->uri($muri)->proxy($self->{'URL'})->$meth( @parms );



  foreach my $p ( $iface->Parms ){
    next unless $p->phase() ne 'I';
    if (my $s = $p->structure ){
      my $res = $som->valueof("//Envelope/Body/$element/".$p->name());
#      print STDERR "//Envelope/Body/$element/".$p->name()."\n".Dumper($res);
      foreach my $f ( $s->Fields ){
        $s->Fieldvalue($f, $res->{$f});
      }
    } else {
      my $res = $som->valueof("//Envelope/Body/$element/".$p->name());
#      print STDERR "//Envelope/Body/$element/".$p->name()."\n".Dumper($res);
      $p->value($res);
    }
  }
  
  foreach my $t ( $iface->Tabs ){
    my @res = $som->valueof("//Envelope/Body/$element/".$t->name()."/item");
    $t->empty;
    $t->rows( \@res );
  }

  return $iface;

}



=head1 NAME

SAP::WAS::SOAP - SOAP encoded RFC calls against SAP R/3 / Web Application Server (WAS)

=head1 SYNOPSIS

#  Setup up a service in the SAP WAS server for an RFC-XML based call to RFC_READ_REPORT
#   called test:ReadReport to make this example work

  use SAP::WAS::SOAP;
  use Data::Dumper;

  my $url = 'http://localhost:8080/sap/bc/soap/rfc';
  my $rfcname = 'RFC_READ_REPORT';

  # build the connecting object
  my $sapsoap = new SAP::WAS::SOAP( URL => $url );

  #  Discover the interface definition for a function module
  my $i = $sapsoap->Iface( $rfcname );

  #  set a parameter value of the interface
  $i->Parm('PROGRAM')->value('SAPLGRAP');

  # call the WAS soap service with an interface object
  $sapsoap->soaprfc( $i );

  print "Name:", $i->TRDIR->structure->NAME, "\n";

  print "Array of Code Lines ( a hash per line including struture fieldnames ):\n";
  print Dumper ( $i->Tab('QTAB')->rows );



=head1 DESCRIPTION

Enabler for HTTP based SOAP calls to SAP using the WAS ( Web Application Server ) using the ICMAN interface ( SAP's Internet Connection MANager ).
You need to ensure that login to the /sap/bc/soap/rfc service has been configured correctly using SAP transaction SICF, first, or this will not work ( under the version 6.10 WAS that I used the only thing I had to change was the settings for the auto login user ) - this corresponds directly to the URL that is supplied to the SAP::WAS::SOAP constructor.


=head1 METHODS:

	my $rfc = new SAP::WAS::SOAP( URL => <url to my WAS SOAP interface > );

	my $i = $rfc->Iface( <some RFC name> );

	< set some parameters in the interface object > .....

	$rfc->soaprfc( $i ); # execute the rfc call encoded in SOAP via the WAS


=head1 AUTHOR

Piers Harding, saprfc@kogut.demon.co.uk.

But Credit must go to all those that have helped.


=head1 SEE ALSO

perl(1), SAP::WAS::SOAP(3), SAP::WAS::Iface(3)

=cut

1;
