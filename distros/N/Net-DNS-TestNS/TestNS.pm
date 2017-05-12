package Net::DNS::TestNS;
use XML::LibXML;
use IO::File;


use Data::Dumper;
use strict;
use warnings;
use Carp;

require Exporter;


our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.


our @EXPORT_OK = qw ( 
);

our @EXPORT = qw(

);


use vars qw( $AUTOLOAD 
	     $LastRevision 
	     $VERSION 
	     $errorcondition
	     $TESTNS_DTD
	     $TESTNS_DTD_0
	     $TESTNS_DTD_1_0
);
$VERSION = (qw$LastChangedRevision: 461 $)[1];
	       
	       
	       
use Net::DNS::TestNS::Nameserver;
use Net::DNS;

   
my $verbose=0;






sub get_dtd {
    return $TESTNS_DTD;
}	    


	    
sub new {
    my $class = shift;
    my $self = {};
    bless $self,ref $class || $class;
    my ($configfile,$params)=@_;

    $self->{servercount}=0;
    $self->{verbose} = ${$params}{Verbose} || $verbose;
    $self->{validate} = 1;
    $self->{validate} = ${$params}{Validate} if defined ${$params}{Validate};


    if (! $configfile){
	$errorcondition="No config file specified" ;
	return 0;
    }
    if (! -f $configfile){
	$errorcondition="$configfile does not exist" ;
	return 0;
    }
    
    my $docstring;
    
    $docstring=$self->_preprocess_input("",$configfile);
    
    return 0 unless $docstring;
    
    my $parser=XML::LibXML->new();



    my $doc=$parser->parse_string($docstring);


    my $root=$doc->getDocumentElement; 
    my $DTD_version=$root->findvalue('@version');
    my $dtd_str=$TESTNS_DTD_0 if ! $DTD_version;  
    $dtd_str=$TESTNS_DTD_1_0 if $DTD_version eq "1.0"; 
    carp "Could not determine DTD version from configuration file" unless $dtd_str;
    my $dtd= XML::LibXML::Dtd->parse_string($dtd_str);
    $doc->validate($dtd) if  $self->{'validate'};

    print STDERR "Warning version not defined assuming version 0 of the DTD.\n".
      Carp::shortmess ."\n"
	unless 	$DTD_version;

    my $servercount=0;

    foreach my $server ($root->findnodes('server')){
	my %answerdb;

	my $ip=$server->findvalue('@ip');
	$ip =~ s/\s*//g;
	my $port=$server->findvalue('@port');
	print "---------Server $ip ($port) ----------------\n" if $self->{verbose};

	foreach my  $qname  ($server->findnodes('qname')){
	      my $query_name= $qname->findvalue('@name');
	      if ($query_name =~ /\s/){
		  $errorcondition="spaces in queryname are not allowed";
		   return 0;
		   #next;
	      }
	      $query_name.="." if $query_name !~ /\.$/;
	      
	    foreach my  $qtype  ($qname->findnodes('qtype')){
	      my $query_type= $qtype->findvalue('@type');
	       if (exists $answerdb{$query_name}->{$query_type}){
		   $errorcondition= "There is allready data for $query_name,$query_type";
		   return 0;
		   #next;
	       }
	      
	      print "<qname,qtype>=$query_name,$query_type\n" if $self->{verbose};

	      my $delay= $qtype->findvalue('@delay');
	      $answerdb{$query_name}->{$query_type}->{'delay'}=0;
	      
	      if ($delay=~/^\d+$/){
		  $answerdb{$query_name}->{$query_type}->{'delay'}=$delay ;
	      }
	      
	      if (! $DTD_version){
		  $answerdb{$query_name}->{$query_type}->{'rcode'}=
		      $qtype->findvalue('@rcode');
		  $answerdb{$query_name}->{$query_type}->{'header'}->{"aa"}= 
		      $qtype->findvalue('@aa');
		  $answerdb{$query_name}->{$query_type}->{'header'}->{"ad"}= 
		      $qtype->findvalue('@ad');
		  $answerdb{$query_name}->{$query_type}->{'header'}->{"ra"}= 
		      $qtype->findvalue('@ra');
	      } else {
		  my @header= $qtype->findnodes('header');
		  carp "Other than one header node" if scalar @header != 1;
		  {
		      my @rcode=$header[0]->findnodes('rcode');
		      carp "Other than one rcode node" if scalar @rcode != 1;
		      my $rcode_val=$rcode[0]->findvalue('@value');
		      croak "No rcode found" unless $rcode_val;
		      print "RCODE: $rcode_val\n" if $self->{verbose};
		      $answerdb{$query_name}->{$query_type}->{'rcode'}= $rcode_val;
		  }
		  
		  # Parse the required fields
		  foreach my $headerfield qw( aa  ra ){
		      my @fields=$header[0]->findnodes($headerfield);
		      carp "Only one $headerfield node is allowed" if scalar @fields != 1;
		      my $field_val=$fields[0]->findvalue('@value');
		      croak "No $headerfield value found" unless defined $field_val;
		      print uc($headerfield).": $field_val\n" if $self->{verbose};
		      $answerdb{$query_name}->{$query_type}->{'header'}->{$headerfield}= $field_val;
		  }
		  
		  
		  # Parse the non-required fields
		  foreach my $headerfield qw( ad cd qr rd tc id qdcount ancount nscount adcount){
		      my @fields=$header[0]->findnodes($headerfield);
		      next unless @fields;
		      carp "More than one $headerfield node is allowed" if scalar @fields != 1;
		      my $field_val=$fields[0]->findvalue('@value');
		      print uc($headerfield).": $field_val\n" if $self->{verbose};
		      $answerdb{$query_name}->{$query_type}->{'header'}->{$headerfield}= $field_val;
		  }



	      } # End DTD_VERSION specific parsing.
	      my @raw=$qtype->findnodes('raw');

	      if (@raw){
		  my $rawhex=$raw[0]->findvalue(".");
		  $rawhex =~s/\s*//g;
		  my $packetdata=pack("H*",$rawhex);
		  $answerdb{$query_name}->{$query_type}->{'raw'}=$packetdata;
	      }else{
		  # not @raw, which should be the default for DTD version 0.
		  foreach my $ans ($qtype->findnodes('ans')){
		      my $rr_string=$ans->findvalue(".");
		      $rr_string =~s/\n//g;
		      next if $rr_string =~ /^\s*$/;
		      my $ans_rr= Net::DNS::RR->new( $rr_string );
		      if ($ans_rr){
			  push @{$answerdb{$query_name}->{$query_type}->{'answer'}}, $ans_rr;
		      }else{
			  $errorcondition= " Could not parse $rr_string\n";
			  return 0;
		      }
		  }
		  foreach my $ans ($qtype->findnodes('aut')){
		      my $rr_string=$ans->findvalue(".");
		      next if $rr_string =~ /^\s*$/;
		      $rr_string =~s/\n//g;
		      my $ans_rr= Net::DNS::RR->new( $rr_string );
		      if ($ans_rr){
			  push @{$answerdb{$query_name}->{$query_type}->{'authority'}}, $ans_rr;
		      }else{
			  $errorcondition= " Could not parse $rr_string\n";
			  return 0;
		      }
		  }
		  foreach my $ans ($qtype->findnodes('add')){
		      my $rr_string=$ans->findvalue(".");
		      next if $rr_string =~ /^\s*$/;
		      $rr_string =~s/\n//g;
		      my $ans_rr= Net::DNS::RR->new( $rr_string );
		      if ($ans_rr){
			  push @{$answerdb{$query_name}->{$query_type}->{'additional'}}, $ans_rr;
		      }else{
			  $errorcondition= " Could not parse $rr_string\n";
			  return 0;
		      }
		  }

		  if ( my @opt=($qtype->findnodes('opt'))){
		      my $optrr;
		      
		      
		      my $size=$opt[0]->findvalue('@size');
		      die "Sorry $size should be specified" unless defined $size;

		      my @flag=$opt[0]->findnodes('flag');
		      my $ednsflags=pack("n",0);
		      if (@flag) {
			  my $flagvalue=$flag[0]->findvalue('@value');
			  if ($flagvalue =~ /^\s*\d+\s*$/){
			      $ednsflags=$flagvalue;
			  }elsif($flagvalue =~ /\s*0x(.+)\s*/i){
			      $ednsflags=
				  unpack("n",pack("H*",$1));

			  }else{
			      die "Sorry I could not parse $flagvalue\n";
			  }


			  print "EDNSFLAGS: ". sprintf("0x%04x", $ednsflags) ."\n" if $self->{'verbose'};
			  
		      }else{
                          # Since we only have one option we'll do an
                          # assignment.
			  my @options=$opt[0]->findnodes("options");
			  my $dobit=$options[0]->findvalue('@do');
			  $ednsflags = 0x8000 if $dobit;
		      }
		      
		      $optrr= Net::DNS::RR->new(
						Type         => 'OPT',
						Name         => '',
						Class        => $size,  # Decimal UDPpayload
						ednsflags    => $ednsflags, # first bit set see RFC 3225 
						);

		      push @{$answerdb{$query_name}->{$query_type}->{'additional'}}, $optrr;

		  }
	      } # end not @raw

	  }
	      
	      
	      
	  }
	
	
	# The XML has been parsed and all info sits in the %answer db..
	# We now construct the reply handler using that.
	my $reply_handler = sub {
	    my ($qname, $qclass, $qtype) = @_;
	    $qname.="." if $qname !~ /\.$/;
	    my ($rcode, @ans, @auth, @add);
	    if ( exists $answerdb{$qname}->{$qtype}){
		$rcode= $answerdb{$qname}->{$qtype}->{'rcode'}; 
		my $transporthash= { 
		    'aa' => 
			$answerdb{$qname}->{$qtype}->
		    {'header'}->{'aa'},
			'ra' => 
			$answerdb{$qname}->{$qtype}->
		    {'header'}->{'ra'},
		    };
		
		foreach my $headerfield qw(aa qr ad rd tc id cd
					   qdcount ancount nscount arcount ){
		    $transporthash->{$headerfield}= $answerdb{$qname}->{$qtype}->
		    {'header'}->{$headerfield} if defined 
		    $answerdb{$qname}->{$qtype}->{'header'}->{$headerfield} ;
		}
		
		print "Sleeping for " . $answerdb{$qname}->{$qtype}->{'delay'} 
		. " seconds " 
		    if $self->{verbose} && $answerdb{$qname}->{$qtype}->{'delay'};
		
		sleep ($answerdb{$qname}->{$qtype}->{'delay'});
		
		if (defined($answerdb{$qname}->{$qtype}->{'raw'})){
		    $transporthash->{'raw'}=$answerdb{$qname}->{$qtype}->{'raw'};
		}
		
		
		return ($rcode, $answerdb{$qname}->{$qtype}->{'answer'},
			$answerdb{$qname}->{$qtype}->{'authority'},
			$answerdb{$qname}->{$qtype}->{'additional'},
			$transporthash);
		
	    }
	    
	    return ("SERVFAIL");
	};
	print "Setting up server for: $ip,$port\n" if $self->{verbose};


	my $ns; 
	$ns= Net::DNS::TestNS::Nameserver->new(
				       LocalPort	   => $port,
				       LocalAddr           => $ip,
				       ReplyHandler => $reply_handler,
				       Verbose	   => $self->{verbose},
				       );
	

	if (! $ns ){
	    $errorcondition="Could not create Nameserver object";
	    return 0;
	}

	$self->{'serverinstance'}->[$servercount]->{'server'}=$ns;
	$self->{'serverinstance'}->[$servercount]->{'_child_pid'}="_not_running";
	$servercount++;
    } #end looping over all servers.
    


    $self->{'servercount'}=$servercount;
    #
    #  Now dynamically set up the reply handler.
    # 
    # 
    return bless $self, $class;

}



sub run {
    my $self=shift;
    my $servercount=0;
    
    while ( $servercount <  $self->{'servercount'} ){
	
	if ($self->{'serverinstance'}->[$servercount]->{'_child_pid'} ne
	    "_not_running" ){
	    print "This instance allready has a server running\n";
	    return ;
	}
	
	
	my $pid;
      FORK: {
	  no strict 'subs';  # EAGAIN
	  if ($pid=fork) {# assign result of fork to $pid,
	      # see if it is non-zero.
	      # Parent process here
	      # Child pid is in $pid
	      print "Child Process: ".$pid."\n" if $self->{verbose};
	      $self->{'serverinstance'}->[$servercount]->{'_child_pid'}=$pid;
	      
	  } elsif (defined($pid)) {
	      # Child process here
	      #parent process pid is available with getppid
	      # exec will transfer control to the child process,
	      # and will finish (exit) when the tar is done.

	      #Verbose level is set during construction.. The verbose method
	      # may have been called afterward.

	      $self->{'serverinstance'}->[$servercount]->{'server'}->{"Verbose"}=$self->verbose;
	      $self->{'serverinstance'}->[$servercount]->{'server'}->main_loop;
	  } elsif ($! == EAGAIN) {
	      # EAGAIN is the supposedly recoverable fork error
	      sleep 5;
	      redo FORK;
	  }else {
	      #weird fork error
	      die "Can't fork: $!\n";
	  }
      }
	
	$servercount++;
    }
    1;
    
}
 

sub _preprocess_input {
    my $self=shift;
    my $outstring=shift;
    my $filename=shift;
    my $infile=new IO::File;
	if ($infile->open("< $filename")) {
	    while (<$infile>){
		if (/^(.*)(<!--\s*include=\"\s*(.*)\s*\"\s*-->)(.*)$/){
		    my $newfile=$3;
		    print "including $newfile\n" if $self->{verbose};
		    $outstring= $outstring. $1;
		    $outstring=$self->_preprocess_input($outstring,$newfile);
		    return 0 unless $outstring;
		    $outstring= $outstring. $4;
		}else{
		    $outstring= $outstring. $_;
		}   
	    }
	}else{
	    $errorcondition= "Could not open $filename during preporcessing";
	    return 0;
	}
    return $outstring;
}


sub verbose {
    my $self=shift;
    my $argument=shift;
    $self->{verbose}=$argument if defined($argument);
    return $self->{verbose};
}

sub stop {
    my $self=shift;
    $self->medea(@_);
}




sub medea {
    my $self=shift;

    my $servercount=0;
    
    while ( $servercount <  $self->{'servercount'} ){
	
	if ($self->{'serverinstance'}->[$servercount]->{'_child_pid'} ne 
	    '_not_running'){
	    if (  kill(15, $self->{'serverinstance'}->[$servercount]->{'_child_pid'}) != 1 ){
		die "UNABLE TO KILL CHILDREN. KILL ".$self->{'serverinstance'}->[$servercount]->{'_child_pid'}." BY HAND";
	    }

	    print "Killed ".$self->{'serverinstance'}->[$servercount]->{"_child_pid"}."\n" if $self->{verbose};
	    $self->{'serverinstance'}->[$servercount]->{"_child_pid"}="_not_running";

	} else {
	    # The child is not running...
	}
	$servercount++;
    }
}
     
sub DESTROY {
    # Time for Greek Drama
    # All children should be killed...
    # 
    my $self=shift;
    $self->medea;
}




sub AUTOLOAD {
        my ($self) = @_;

        my $name = $AUTOLOAD;
        $name =~ s/.*://;

        Carp::croak "$name: no such method" unless exists $self->{$name};
        
        no strict q/refs/;
	
        # AUTOLOADER sets and reads existing variables.
        *{$AUTOLOAD} = sub {
                my ($self, $new_val) = @_;
                
                if (defined $new_val) {
                        $self->{"$name"} = $new_val;
                }
                
                return $self->{"$name"};
        };
        
        goto &{$AUTOLOAD};      
}






BEGIN {
    $TESTNS_DTD_0='
     <!ELEMENT testns (server*)>


     <!-- Root element has required IP and PORT attribute -->
     <!ELEMENT server (qname+)>
     <!ATTLIST server ip  CDATA #REQUIRED>
     <!ATTLIST server port  CDATA #REQUIRED>

     <!-- A server has answers for a number of possible   -->
     <!-- QAME QTYPE questions                            -->
     <!-- A QNAME should be fully specified               -->

     <!ELEMENT qname (qtype*)>

     <!ATTLIST qname name CDATA #REQUIRED>
     <!ELEMENT qtype (ans*,aut*,add*)>
     <!ATTLIST qtype type CDATA #REQUIRED>
     <!ATTLIST qtype rcode CDATA #REQUIRED>
     <!ATTLIST qtype aa (1|0)  #REQUIRED>
     <!ATTLIST qtype ra (1|0)  #REQUIRED>
     <!ATTLIST qtype ad (1|0)  #REQUIRED>
     <!ATTLIST qtype delay CDATA "0" >
     <!--  Each of these contain one RR. -->
     <!ELEMENT ans (#PCDATA) >
     <!ELEMENT aut (#PCDATA) >
     <!ELEMENT add (#PCDATA) >
';


# Note: generateDTDpod.pl asumes the DTD is stored as $TESNS_DTD and
# has a rather "loose" way to determine the begin and the end of the
# string.  Start: if (s/\$TESTNS_DTD=\'//){ End: if (s/\'\;//){

    $TESTNS_DTD='

 <!-- The testns DTD has "testns" as root element         -->
 <!-- It has a version number that is enforced by the DTD -->
 <!-- You are currently looking at version 0.01 of the    -->
 <!-- DTD.                                                -->
 <!-- it contains one or more server elements             -->

 <!ELEMENT testns (server+)>
 <!ATTLIST testns  version CDATA #FIXED "1.0">

 <!-- The server requieres an ip and a port attribute     -->
 <!-- these define to which IP/PORT combination the       -->
 <!-- server  should bind to                              -->

 <!-- The server will respond to particular QNAME/QTYPE   -->
 <!-- queries. These are enumerated in the qname elements -->
 <!-- that hang of this server                            -->

 <!ELEMENT server (qname+)>
 <!ATTLIST server ip  CDATA #REQUIRED>
 <!ATTLIST server port  CDATA #REQUIRED>


 <!-- A server has answers for a number of possible       -->
 <!-- QNAME QTYPE questions.                              -->

 <!-- A QNAME name attribute should be fully specified    -->
 <!--  domain name.                                       -->

  <!ELEMENT qname (qtype*)>
  <!ATTLIST qname name CDATA #REQUIRED>

  <!-- each qtype element contains a DNS packet           -->
  <!-- specification.                                     -->
  
  <!-- First specify the header and then then choose      -->
  <!-- to specify an hexadecimal dump of the packet (raw) -->
  <!-- or define all the sections one by one              -->

  <!ELEMENT qtype (header,
                   ((question?,ans*,aut*,add*,opt?)
                    |raw)
                   )>

  <!ATTLIST qtype type CDATA #REQUIRED>
  <!ATTLIST qtype delay CDATA "0" >



   <!ELEMENT header (rcode,aa,ra,
                     ad?, cd?, qr?,rd?,tc?,id?,
                     qdcount?,ancount?,nscount?,arcount?)>

 
     <!-- These are all the header elements that can be   -->
     <!-- modified with this code                         -->
     <!ELEMENT rcode EMPTY>
       <!ATTLIST rcode value CDATA #REQUIRED>
     <!ELEMENT aa EMPTY>
       <!ATTLIST aa value (1|0)  #REQUIRED>
     <!ELEMENT ra EMPTY>
       <!ATTLIST ra value (1|0)  #REQUIRED>
     <!ELEMENT ad EMPTY>
       <!ATTLIST ad value (1|0)  #REQUIRED>
     <!ELEMENT cd EMPTY>
       <!ATTLIST cd value (1|0)  #REQUIRED>

     <!ELEMENT qr EMPTY>
       <!ATTLIST qr value (1|0)  #REQUIRED>
     <!ELEMENT rd EMPTY>
       <!ATTLIST rd value (1|0)  #REQUIRED>
     <!ELEMENT tc EMPTY>
       <!ATTLIST tc value (1|0)  #REQUIRED>

     <!ELEMENT id EMPTY>
       <!ATTLIST id value CDATA  #REQUIRED>
     <!ELEMENT qdcount EMPTY>
       <!ATTLIST qdcount value CDATA  #REQUIRED>
     <!ELEMENT ancount EMPTY>
       <!ATTLIST ancount value CDATA  #REQUIRED>
     <!ELEMENT nscount EMPTY>
       <!ATTLIST nscount value CDATA  #REQUIRED>
     <!ELEMENT arcount EMPTY>
       <!ATTLIST arcount value CDATA  #REQUIRED>

     <!--  Each of these contain "One RR" in zonefile    -->
     <!--  format.                                       -->
     <!--  See Net::DNS::Question for format of the      -->
     <!--  question section                              -->
     <!ELEMENT question (#PCDATA) >

     <!ELEMENT ans (#PCDATA) >
     <!ELEMENT aut (#PCDATA) >
     <!ELEMENT add (#PCDATA) >
     <!--  question section                              -->
     <!-- The OPT RR is used for EDNSO purposes          -->
     <!-- It contains a size attribute that is used to   -->
     <!-- negotiate packet sizes                         -->
     <!-- It has either a flag or an options element     -->
     <!-- included                                       -->

     <!ELEMENT opt (flag|options)>
     <!ATTLIST opt size CDATA  #REQUIRED>

     <!-- The flag element has a data attribute that     -->
     <!-- contains a 2byte value that sets the flags     -->
     <!-- alternatively you can use the options          -->
     <!-- element to set these flags                     -->
     <!-- <options do=1/> is equivalent to               -->
     <!-- <flag value="0x8000" />                        -->

     <!ELEMENT flag EMPTY>
     <!ATTLIST flag value CDATA  #REQUIRED>

     <!ELEMENT options EMPTY>
     <!ATTLIST options do (1|0)  #REQUIRED>

     <!--  The raw elemet is to contain a hexadecimal    -->
     <!--  representation of the packet. Whitespaces and -->
     <!--  XML comments are ignored.                     -->
     <!--  The raw element should contain all sections,  -->
     <!--  including the question section but does not   -->
     <!--  include header information.                   -->
     <!--  Take care that the header information is      -->
     <!--  consistent with the packet content.           -->
     <!ELEMENT raw (#PCDATA) >


     <!-- This DTD has been generated from               -->
     <!-- Net::DNS::TestNS   $LastChangedRevision: 461 $ -->


';

    $TESTNS_DTD_1_0=$TESTNS_DTD;

} #END BEGIN








=head1 NAME

Net::DNS::TestNS - Perl extension for simulating simple Nameservers

=head1 SYNOPSIS

use Net::DNS::TestNS;
  

=head1 ABSTRACT

Class for setting up "simple DNS" servers.

=head1 DESCRIPTION

Class to setup a number of nameservers that respond to specific DNS
queries (QNAME,QTYPE) by prespecified answers. This class is to be
used in test suites where you want to have servers to show predefined
behavior. 

If the server will do a lookup based on QNAME,QTYPE and return the
specified data. If there is no QNAME, QTYPE match the server will
return a SERVFAIL.

A log will be written to STDERR it contains time, IP/PORT, QNAME,
QTYPE, RCODE

=head2 Configuration file

The class uses an XML file to read its configuration. The DTD is documented
in L<Net::DNS::TestNS::DTD>.


The setup is split in a number of servers, each with a unique IP/port
number, each server has 1 or more QNAMEs it will respond to. Each
QNAME can have QTYPEs specified.

For each QNAME,QTYPE an answer needs to be specified, response code
and header bits can be tweaked through the qtype attributes.

The content of the packet can be specified through ans, aut and add
elements, each specifying one RR record to end up in the answer,
authority or additional section.

The optional 'delay' attribute in the QTYPE element specifies how many
seconds the server should wait until an answer is returned.


If the query does not match against data specified in the
configuration a SERVFAIL is returned.

=head2 new 


    my $server=Net::DNS::TestNS->new($configfile, {
     Verbose => 1,
        Validate => 1,
    });



Read the configuration files and bind to ports.  One can use <!--
include="file" --> anywhere inside the configuration file to include
other XML configuration fragments.

The second optional argument is hash that contains customization parameters.
    Verbose  boolean     Makes the code more verbose.
    Validate boolean     Turns on XML validation based 
                         on the DTD
                         The parser is flexible with 
                         respect to the ordering 
                         of some of the XML elements. 
                         The DTD is not.
                         Validation is on by default.                      



new returns the object reference on success and 0 on failure. On
failure the class variable $Net::DNS::TestNS::errorcondition is set.



=head2 verbose

    $self->verbose(1);

Sets verbosity at run time.

=head2 run
 
Spawns off the servers and process the data.
 
=head2 medea

Cleanup function that kills all the children spawned by the
instance.  Also known by its alias 'stop'.

=head1 Configuration file example


<?xml version="1.0" standalone="no"?>
 <testns version="1.0">
 <server ip="127.0.0.1" port="5354">
   <qname name="bla.foo">
     <qtype type="TXT" delay="1">
      <header>
        <rcode value="NOERROR"/>
        <aa value="1"/>
        <ra value="0"/>
        <ad value="0"/>
        <qr value="0"/>
        <tc value="1"/>
        <id value="1234"/>
        <ancount value="1"/>
        <nscount value="1"/>
      </header>
      <ans>
        bla.foo.  3600 IN TXT "TEXT"
      </ans>
      <ans>
        bla.foo.          3600     IN     TXT     "Other text"  
      </ans>
     </qtype>
   </qname>
   <qname name="raw.foo">
    <qtype type="TXT" delay="1">
     <header>
      <rcode value="NOERROR"/>
        <aa value="1"/>
        <ra value="0"/>
        <ad value="0"/>
        <qr value="0"/>
        <tc value="1"/>
        <id value="1234"/>
       <ancount value="1"/>        
      </header>
    <raw>
     <!-- QNAME -->
     07 74726967676572   <!-- trigger -->
     03 666f6f           <!-- foo -->
     00                  <!-- closing octet  -->
     <!-- QTYPE -->
     00 01               <!-- A RR -->
     <!-- QCLASS -->
     00 01
 
   <!-- Answer section -->

     c0 0c               <!-- Points up -->
     00 01               <!-- type A -->
     00 01               <!-- class IN -->
     00 00 00 05         <!-- ttl 5 seconds  -->
     00 04               <!-- RD length 4 octets -->
     0a 00 00 01         <!-- 10.0.0.1 -->
     </raw>
   </qtype>
  </qname>
    
 </server>
</testns>


=head1 Known Deficiencies and TODO

The module is based on Net::DNS::Nameserver. There is no way to
distinguish if the query came over TCP or UDP; besides UDP truncation
is not available in Net::DNS::Nameserver. 

Earlier versions of this script used a different DTD that had no
version number. The script only validates against version 1.0 of the
DTD but parses the old files.


==head1 ALSO SEE
L<Net::DNS::TestNS::DTD>, L<Net::DNS>, L<Net::DNS::RR>

=head1 AUTHOR

Olaf Kolkman, E<lt>olaf@net-dns.org<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2005  RIPE NCC.  Author Olaf M. Kolkman  <olaf@net-dns.net>

All Rights Reserved

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be
used in advertising or publicity pertaining to distribution of the
software without specific, written prior permission.


THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS; IN NO EVENT SHALL
AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


=cut



1;
__END__

