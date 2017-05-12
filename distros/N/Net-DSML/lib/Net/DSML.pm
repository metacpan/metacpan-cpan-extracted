package Net::DSML;


use warnings;
use strict;
#use Carp;
use Class::Std::Utils;
use LWP::UserAgent;

# Copyright (c) 2007 Clif Harden <charden@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use version; $VERSION = version->new('0.003');

{

BEGIN
{
  use Exporter ();

  @ISA = qw(Exporter);
  @EXPORT = qw();
  %EXPORT_TAGS = ();
  @EXPORT_OK  = ();
}

my %ops;           # items container
my %pid;           # process id container
my %content;       # Returned ldap data
my %prepostData;   # Returned ldap data
my %errMsg;        # no error this will be a null string.
my %psize;         # Size of xml string.
my %postData;      # Actual xml data string.
my %operations;    # operations container
my %authentication;    # authentication container

#
# Method new
#
# The method new creates a new DSML oject.
#
# There are two possible input options.
#
# $dsml = Net::DSML->new( debug => 1, url => "http://system.company.com:8080/dsml" );
#
# Input option "debug":  Sets the debug variable to the input value.
# Input option "url":    Sets the host variable to the input value.
#
#
# Input option "process":  String that contains the LDAP process value;
# sequential or parallel.  Default is sequential.
# Input option "type":  String that contains the LDAP scope value;
# true or false.  Default is false.
# Input option "referral":  String that contains the referral control value;
# neverDerefAliases, derefInSearching, derefFindingBaseObj or derefAlways.
# Default is neverDerefAliases.
# Input option "scope":  String that contains the LDAP scope value;
# singleLevel, baseObject or wholeSubtree.  Default is singleLevel.
# Input option "order":  String that contains the LDAP order value;
# sequential or unordered.  Default is sequential.
# Input option "error":  String that contains the LDAP onError value;
# exit or resume.  Default is exit.
# Input option "time":  String that contains the time limit of the
# LDAP search.  Default is "0".
# Input option "size":  String that contains the size limit of the
# LDAP search.  Default is "0".
# Input option "base":  String that contains the LDAP search base.
# Input option "bid":   String that contains the batch request ID
#
#
# Method output;  Returns a new DSML object.
#

sub new
{
my ($class, $opt) = @_;
my $self = bless anon_scalar(),$class;
my $id = ident($self);
my $initerror = "";
my $pnumber = 0;
my $result;
#
# Initailize the data to a default value.
#
$content{$id}    = ""; # Returned ldap data
$psize{$id}      = ""; # Size of xml string.
$postData{$id}   = ""; # Actual xml data string.
$prepostData{$id} = ""; # Actual xml data string.
$errMsg{$id}     = ""; #  error messages, no error this will be a null string.

$ops{$id}->{processing} = " processing=\"sequential\""; # Processing type
$ops{$id}->{sbase}      = ""; # search base
$ops{$id}->{sizelimit}  = " sizeLimit=\"0\"";     # search size limit
$ops{$id}->{timelimit}  = " timeLimit=\"0\"";     # search time limit
$ops{$id}->{onerror}    = " onError=\"exit\"";    # search time limit
$ops{$id}->{responseOrder} = " responseOrder=\"sequential\""; # search time limit
$ops{$id}->{scope}      = " scope=\"singleLevel\"";  # search scope
$ops{$id}->{derefAliases} = " derefAliases=\"neverDerefAliases\"";
$ops{$id}->{typesOnly}  = " typesOnly=\"false\">"; #
$ops{$id}->{auth}       = "";                     # authRequest data

$ops{$id}->{control}    = "";                     # Control data

$ops{$id}->{reqid} = " requestID=\"batch request\"";  # request ID
$ops{$id}->{host}  = (ref($opt->{url}) ? ${$opt->{url}} : $opt->{url}) if ( $opt->{url} ); # ldap host
$ops{$id}->{debug} = $opt->{debug} ? 1 : 0;  # debug flage
$ops{$id}->{pid} = "";  # initial process id.
$pid{$id}->{pid} = 1;  # initial process id.

$operations{$id} = [];
$result = 1;

$result = $self->setProcess({ process => (ref($opt->{process}) ? ${$opt->{process}} : $opt->{process}) }) if ( $opt->{process}); 
$initerror .= $errMsg{$id} if (!$result);

$result = $self->setType( { type => (ref($opt->{type}) ? ${$opt->{type}} : $opt->{type}) } ) if ( $opt->{type} );
$initerror .= "\t" . $errMsg{$id} if (!$result);

$result = $self->setReferral( { referral => (ref($opt->{referral}) ? ${$opt->{referral}} : $opt->{referral}) } ) if ( $opt->{referral} );
$initerror .= "\t" . $errMsg{$id} if (!$result);

$result = $self->setScope( { scope => (ref($opt->{scope}) ? ${$opt->{scope}} : $opt->{scope}) } ) if ( $opt->{scope} );
$initerror .= "\t" . $errMsg{$id} if (!$result);

$result = $self->setOrder( { order => (ref($opt->{order}) ? ${$opt->{order}} : $opt->{order}) } ) if ( $opt->{order} );
$initerror .= "\t" . $errMsg{$id} if (!$result);

$result = $self->setOnError( { error => (ref($opt->{error}) ? ${$opt->{error}} : $opt->{error})} ) if ( $opt->{error} );
$initerror .= "\t" . $errMsg{$id} if (!$result);

$result = $self->setTime( { time => (ref($opt->{time}) ? ${$opt->{time}} : $opt->{time}) } ) if ( $opt->{time} );
$initerror .= "\t" . $errMsg{$id} if (!$result);

$result = $self->setSize( { size => (ref($opt->{size}) ? ${$opt->{size}} : $opt->{size}) } ) if ( $opt->{size} );
$initerror .= "\t" . $errMsg{$id} if (!$result);

$result = $self->setBase( { base => (ref($opt->{base}) ? ${$opt->{base}} : $opt->{base}) } ) if ( $opt->{base} );
$initerror .= "\t" . $errMsg{$id} if (!$result);

$result = $self->setProxy( { dn => (ref($opt->{proxyid}) ? ${$opt->{proxyid}} : $opt->{proxyid}) } ) if ( $opt->{proxyid} );
$initerror .= "\t" . $errMsg{$id} if (!$result);

$result = $self->setBatchId( { id => (ref($opt->{bid}) ? ${$opt->{bid}} : $opt->{bid}) } ) if ( $opt->{bid} );
$initerror .= "\t" . $errMsg{$id} if (!$result);

$errMsg{$id} = $initerror;


if ( $opt->{dn} && $opt->{password} )
{
  $authentication{$id}->{dn} = (ref($opt->{dn}) ? ${$opt->{dn}} : $opt->{dn});
  $authentication{$id}->{password} = (ref($opt->{password}) ? ${$opt->{password}} : $opt->{password});
}

return $self;
}

#
# inside-out classes have to have a DESTROY subrountine.
#
sub DESTROY
{
  my ($dsml) = @_;
  my $id = ident($dsml);

  delete $ops{$id};           # items container
  delete $content{$id};       # Returned ldap data
  delete $psize{$id};         # Size of xml string.
  delete $postData{$id};      # Actual xml data string.
  delete $prepostData{$id};   # Copy of actual xml data string.
  delete $errMsg{$id};        # no error this will be a null string.
  delete $operations{$id};    # operations container
  delete $authentication{$id};    # authentication container
  delete $pid{$id};               # initial process id.
  return;
}

#   1.  & - &amp;
#   2. < - &lt;
#   3. > - &gt;
#   4. " - &quot;
#   5. ' - &#39;
#
#   Convert special characters to xml standards.
#
sub _specialChar
{
  my ($char) = @_;

  $$char =~ s/&/&amp;/g;
  $$char =~ s/</&lt;/g;
  $$char =~ s/>/&gt;/g;
  $$char =~ s/"/&quot;/g;
  $$char =~ s/'/&#39;/g;
  return;
}

#
# Constant values
#
# The string postHead provides the xml "Header" string.  
# This "Header" string is standard with all DSML XML strings.
#
my $postHead = "<?xml version='1.0' encoding='UTF-8'?><soap-env:Envelope xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:soap-env='http://schemas.xmlsoap.org/soap/envelope/'><soap-env:Body>";

# The string postTail provides the xml "Tail" string.  
# This "Tail" string is standard with all DSML XML strings.
#
my $postTail = "</soap-env:Body></soap-env:Envelope>";

# The string postPing provides the xml "Body" string for a DSML ping request.  
# The DSML ping request is used to tell if the DSML functions are provided.
#
my $postPing = "<batchRequest xmlns='urn:oasis:names:tc:DSML:2:0:core' requestID='Ping!'><!-- empty batch request -->";

# The string postDSE provides the ending xml "Body" string for a DSML 
# rootDSE request.  The DSML rootDSE request is used to get the directory 
# rootDSE information.
#
my $postDSE = "</attributes>";

# The string preBatch provides the initial batchRequest xml "Body" string 
# for a DSML request.  
#
my $preBatch = "<batchRequest xmlns='urn:oasis:names:tc:DSML:2:0:core' ";

# The string postBatch provides the ending batchRequest xml "Body" 
# string for a DSML request.   
#
my $postBatch = "</batchRequest>";

# The string preAuth provides the authorization xml "Body" string for a DSML
# authRequest.  
#
my $preAuth = "<authRequest principal=\"dn:";

# The string postAuth provides the ending authorization xml "Body" string for a 
# DSML authRequest.  
#
my $postAuth = "\"/>";

# The string postSearch provides the ending xml "Body" string for a 
# DSML search request.
#
my $postSearch = "</searchRequest>";

# The string postCompare provides the ending xml "Body" string for a 
# DSML search request.
#
my $postCompare = "</value></assertion>";

# The string reqID provides the initial part of the scope attribute of 
# the batchRequest element.
#
my $reqID = " requestID=\"";

my $prescope = " scope=\"";

# The string deref provides the initial part of the derefAliases attribute 
# of the batchRequest element.
#
my $deref = " derefAliases=\"";

# The string types provides the initial part of the typesOnly attribute 
# of the batchRequest element.
#
my $types = " typesOnly=\"";
my $sizel = " sizeLimit=\"";
my $timel = " timeLimit=\"";
my $orders = " responseOrder=\"";
my $proc = " processing=\"";
my $onE = " onError=\"";

#
# End of constant values.
#

#
# Method setScope
# 
# The method setScope sets the LDAP search scope.
# 
# There is one required input option.
# 
# $return = $dsml->setScope( { scope => "singleLevel" } );
# 
# Input option "scope":  String that contains the LDAP scope value; 
# singleLevel, baseObject or wholeSubtree.  Default is singleLevel.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setScope
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;

  $errMsg{$id} = "";

  if ((ref($opt->{scope}) ? ${$opt->{scope}} : $opt->{scope}) =~ /^(singleLevel||baseObject||wholeSubtree)$/)
  {
    $ops{$id}->{scope} = $prescope . $1 . "\"";
    return 1;
  }

  $errMsg{$id} = "Requested scope value does not match singleLevel, baseObject or wholeSubtree";
  return 0;
}

#
# Method setReferral
# 
# The method setReferral sets the LDAP referral status.
# 
# There is one required input option.
# 
# $return = $dsml->setReferral( { referral => "neverDerefAliases" } );
# 
# Input option "referral":  String that contains the referral control value; 
# neverDerefAliases, derefInSearching, derefFindingBaseObj or derefAlways. 
# Default is neverDerefAliases.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setReferral
{
  my ($dsml,$opt) = @_;
  my $id = ident $dsml;

  $errMsg{$id} = "";

  if ((ref($opt->{referral}) ? ${$opt->{referral}} : $opt->{referral}) =~ /^(neverDerefAliases||derefInSearching||derefFindingBaseObj||derefalways)$/)
  {
    $ops{$id}->{derefAliases} = $deref . $1 . "\"";
    return 1;
  }

  $errMsg{$id} = "Requested setReferral derefAliases value does not match neverDerefAliases, derefInSearching, derefFindingBaseObj or derefAlways.";
  return 0;
}

# Method setType
# 
# The method setType sets the LDAP search scope.
# 
# There is one required input option.
# 
# $return = $dsml->setType( { type => "false" } );
# 
# Input option "type":  String that contains the LDAP scope value; 
# true or false.  Default is false.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setType
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;

  $errMsg{$id} = "";

  if (lc((ref($opt->{type}) ? ${$opt->{type}} : $opt->{type})) =~ /^(false||true)$/ )
  {
    $ops{$id}->{typesOnly} = $types . $1 . "\">";  # The > ends an xml element.
    return 1;
  }

  $errMsg{$id} = "Requested setType value does not match true or false.";
  return 0;
}


# Method setSize
# 
# The method setSize sets the size limit of the LDAP search.
# 
# There is one required input option.
# 
# $return = $dsml->setSize( { size => "0" } );
# 
# Input option "size":  String that contains the size limit of the 
# LDAP search.  Default is "0".
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setSize
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $refvalue;

  $errMsg{$id} = "";
  $refvalue = (ref($opt->{size}) ? ${$opt->{size}} : $opt->{size});

  if (!(length($refvalue)) )
  {
    $errMsg{$id} = "Subroutine setSize size value is not defined.";
    return 0;
  }

  $ops{$id}->{sizelimit} = $sizel . $refvalue ."\"";  # The > ends an xml element.
  return 1;
}


# Method setTime
# 
# The method setTime sets the time limit of the LDAP search.
# 
# There is one required input option.
# 
# $return = $dsml->setTime( { time => "0" } );
# 
# Input option "time":  String that contains the time limit of the
# LDAP search.  Default is "0".
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setTime
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $refvalue;
  $errMsg{$id} = "";
  
  $refvalue = (ref($opt->{time}) ? ${$opt->{time}} : $opt->{time});

  if ( !(length($refvalue)) )
  {
    $errMsg{$id} = "Subroutine setTime time value is not defined.";
    return 0;
  }

  $ops{$id}->{timelimit} = $timel . $refvalue . "\""; 
  return 1;
}


# Method setOrder
# 
# The method setOrder sets the order of the returned  LDAP data.
# 
# There is one required input option.
# 
# $return = $dsml->setOrder( { order => "sequential" } );
# 
# Input option "order":  String that contains the LDAP order value; 
# sequential or unordered.  Default is sequential.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setOrder
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;

  $errMsg{$id} = "";

  if (lc((ref($opt->{order}) ? ${$opt->{order}} : $opt->{order})) =~ /^(sequential||unordered)$/ )
  {
    $ops{$id}->{responseOrder} = $orders . $1 . "\"";   
    return 1;
  }

  $errMsg{$id} = "Requested responseOrder value does not match sequential or unordered.";
  return 0;
}


# Method setProcess
# 
# The method setProcess sets the LDAP DSML processing mode; sequential 
# or parallel.  If you use parallel you must set up a seperate unique 
# requestId for each requested chunk of data.
# 
# There is one required input option.
# 
# $return = $dsml->setProcess( { process => "sequential" } );
# 
# Input option "process":  String that contains the LDAP process value; 
# sequential or parallel.  Default is sequential.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setProcess
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;

  $errMsg{$id} = "";

  if (lc((ref($opt->{process}) ? ${$opt->{process}} : $opt->{process})) =~ /^(sequential||parallel)$/)
  {
    $ops{$id}->{processing} = $proc . $1 . "\""; # Processing type
    return 1;
  }

  $errMsg{$id} = "Requested process value does not match sequential or parallel.";
  return 0;
}


# Method setOnError
# 
# The method setOnError sets the LDAP DSML processing mode for errors; exit 
# or resume.  
# 
# There is one required input option.
# 
# $return = $dsml->setOnError( { error => "exit" } );
# 
# Input option "error":  String that contains the LDAP onError value; 
# exit or resume.  Default is exit.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setOnError
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;

  $errMsg{ident $dsml} = "";
  if ( !(length($opt->{error})) )
  {
    $errMsg{$id} = "Subroutine setOnError required attribute is not defined.";
    return 0;
  }

  if ( lc((ref($opt->{error}) ? ${$opt->{error}} : $opt->{error})) =~ /^(exit||resume)$/ )
  {
    $ops{$id}->{onerror} = $onE . $1 . "\""; # On error action to take
    return 1;
  }

  $errMsg{$id} = "Requested onError value does not match exit or resume.";
  return 0;
}

# Method setBatchId
# 
# The method setBatchId sets the batch operation request id.
# 
# There is one required input option.
# 
# $return = $dsml->setBatchId(  { id => "batch request id" });
# 
# Input option "id":  String that contains the batch operation request id. 
# Default is "search request".
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setBatchId
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $refvalue;

  $errMsg{$id} = "";
  $refvalue = (ref($opt->{id}) ? ${$opt->{id}} : $opt->{id});

  if ( !(length($refvalue)) )
  {
    $errMsg{$id} = "Subroutine setBatchId id string is not defined.";
    return 0;
  }

  $ops{$id}->{reqid} = $reqID . $refvalue . "\"";
  return 1;
}


# Method setProcessId
# 
# The method setProcessId sets the LDAP process operation request id.
# Very important method if parallel processing is enabled because each
# parallel operation must have a unique request id.
# 
# There is one required input option.
# 
# $return = $dsml->setProcessId(  { id => "request id" });
# 
# Input option "id":  String that contains the LDAP operation request id. 
# Default value: 1, incremented after each process.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setProcessId
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $refvalue;
  $errMsg{$id} = "";
  $refvalue = (ref($opt->{id}) ? ${$opt->{id}} : $opt->{id});
  if ( !(length($refvalue)) )
  {
    $errMsg{$id} = "Subroutine setProcessId id value is not defined.";
    return 0;
  }

  $ops{$id}->{pid} = $reqID . $refvalue . "\"";
  return 1;
}

# Method setBase
# 
# The method setBase sets the LDAP search base.
# This is a required method, program must set it.
# 
# There is one required input option.
# 
# $return = $dsml->setBase( { base => "dc=company,dc=com" } );
# 
# Input option "base":  String that contains the LDAP search base.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub setBase
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $refvalue;
  $errMsg{$id} = "";
  $refvalue = (ref($opt->{base}) ? ${$opt->{base}} : $opt->{base});

  if ( !(length($refvalue)) )
  {
    $errMsg{$id} = "Subroutine setBase base value is not defined.";
    return 0;
  }
  _specialChar(\$refvalue) if ( $refvalue =~ /(&||<||>||"||')/);
  $ops{$id}->{sbase} = "\"" . $refvalue . "\"";
  return 1;
}


# Method debug
# 
# The method debug sets or returns the object debug flag.
# 
# If there is one required input option.
# 
# $return = $dsml->debug( 1 );
# 
# Input option:  Debug value; 1 or 0.  Default is 0.
# 
# Method output; Returns debug value.
# 

sub debug
{
  my $dsml = shift;
  $ops{ident $dsml}->{debug} = shift if ( @_ >= 1 );
  return $ops{ident $dsml}->{debug};
}


# Method url
# 
# The method url sets or returns the object url value.
# 
# If there is one required input option.
# 
# $return = $dsml->url( "http://xyz.company.com:8080/dsml" );
# 
# Input option:  Host system name.
# 
# Method output; Returns host value.
# 

sub url
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $refvalue;
  $refvalue = (ref($opt) ? ${$opt} : $opt);
  $ops{$id}->{host} = $refvalue; 
  return $ops{$id}->{host};
}


#
# Method error
# 
# The method error returns the error message for the object.
# $message = $dsml->error();
# 

sub error
{
  my $dsml = shift;
  return $errMsg{ident $dsml};
}


# Method size
# 
# The method size returns the size of the last dsml message sent to the dsml 
# server.
# 
# $size = $dsml->size();
# 

sub size
{
   my $dsml = shift;
   return $psize{ident $dsml};
}


# Method content
# 
# The method content returns the last dsml message received from the 
# dsml server.
# Once the user has the content he or she can use whatever XML parser they
# choose.
# 
# $returnXmlMessage = $dsml->content();
# 

sub content
{
  my $dsml = shift;
  return $content{ident $dsml};
}


# Method Ping
# 
# The method Ping builds a Ping batch request to be sent to the dsml server.  
# A Ping requests is used to confirm the existance of a dsml server on a 
# directory server system.
# 
# 
# $return = $dsml->Ping();
# $return = $dsml->send();    # Post the xml message to the DSML server
# $return = $dsml->content(); # Get the data returned from the DSML server.
# 
# There are no inputs options for this method.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 
# The user must call the send method to actually send the ping request and
# parse the returned xml message to determine if the dsml server responded.
# 

sub Ping
{
  my $dsml = shift;
  my $id = ident $dsml;
  my $result;
  $dsml->setBatchId({id => "Ping!"});
  $result = "<!-- empty batch request -->"; 
  push(@{$operations{$id}},$result);
  return 1;
}


# Method rootDSE
# 
# The method DSE the searchs the root, or dse, of the dsml server. 
# 
# There is one required input option.
# Input option "attributes":  Array of attributes to get information on.
# 
# There is one optional input option.
# Input option "id":  The request ID for this operation.
# 
# $return = $dsml->rootDSE( { attributes => \@attributes } );
# $return = $dsml->send();  # Post the xml message to the DSML server
# $return = $dsml->content(); # Get the data returned from the DSML server.
# 
#
# The scope will automatically be set to the correct value for the user.
#
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 
# The user must parse the returned xml message to determine what the 
# dsml server responded with.
# 

sub rootDSE
{
  my ($dsml,$opt) = @_;
  my $size;
  my $count;
  my $oldscope;
  my $id = ident $dsml;
  my $result;

  $oldscope = $ops{$id}->{scope};

  $count = @{$opt->{attributes}};

  $result = "<searchRequest";

  # Load Process ID

  if ( $opt->{id} )
  {
     $result .= $reqID . (ref($opt->{id}) ? ${$opt->{id}} : $opt->{id}) . "\"";
  }
  elsif ( $ops{$id}->{pid} )
  {
     $result .= $ops{$id}->{pid};
     delete($ops{$id}->{pid});
  }
  else
  {
     $result .= $reqID . $pid{$id}->{pid} . "\"";
     ++$pid{$id}->{pid};
  }

  $result .= " dn=\"\"" . " scope=\"baseObject\"" . $ops{$id}->{derefAliases} . $ops{$id}->{timelimit} . $ops{$id}->{sizelimit} . $ops{$id}->{typesOnly} . "<filter><present name=\"objectClass\"/></filter><attributes>";

  for (my $i = 0; $i < $count; $i++)
  {
    $result .= "<attribute name=\"";
    $result .= ${$opt->{attributes}}[$i];
    $result .= "\"/>";
  }

  $result .= $postDSE;
  $result .= $opt->{control} if ( defined($opt->{control}));
  $result .= "</searchRequest>";
  push(@{$operations{$id}},$result);
  return 1;

}

# 
# Method setProxy
# 
# The method setProxy sets the LDAP authenication dn.
# 
# There is one required input option.
# 
# $return = $dsml->setProxy( { dn => "cn=directory manager" } );
# 
# Input option "dn":  String that contains the LDAP authenication dn .
# 

sub setProxy
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $refvalue;

  $errMsg{$id} = "";
  $refvalue = (ref($opt->{dn}) ? ${$opt->{dn}} : $opt->{dn});
  if ( !(length($refvalue)) )
  {
    $errMsg{$id} = "Subroutine setProxy dn value is not defined.";
    return 0;
  }

  $ops{$id}->{auth} = $preAuth . $refvalue . $postAuth;
  return 1;
}

# Method search
# 
# The method search searchs the dsml server for the requested information.
# 
# If there are two required input options.
# Input option "sfilter":  The filter object that contains the filter string.
# Input option "attributes":  Array reference of attributes to get 
# information on.
# 
# There are 3 optional input options.
# Input option "id":  The request ID for this operation.
# Input option "control":  The Control object that contains the control string.
# Input option "base":  The search base dn.
# 
# $return = $dsml->search( { sfilter => $dsml->getFilter(),
#                            attributes => \@attributes },
#                             control => $control->getControl() );
# $return = $dsml->send();  # Post the xml message to the DSML server
# $content = $dsml->content(); # Get the data returned from the DSML server.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 
# The user must parse the returned xml message to determine what the 
# dsml server responded with.
# 

sub search
{
  my ($dsml, $opt) = @_;
  my $count;
  my $id = ident $dsml;
  my $result;
  $count = @{$opt->{attributes}};
  $errMsg{$id} = "";

  if ( !$count )
  {
    $errMsg{$id} = "Subroutine search attributes are not defined.";
    return 0;
  }

  if ( !(length($opt->{sfilter})) )
  {
    $errMsg{$id} = "Subroutine search search filter is not defined.";
    return 0;
  }

  if ( $opt->{base} )
  {
    if (!$dsml->setBase( {base => (ref($opt->{base}) ? ${$opt->{base}} : $opt->{base}) }))
    {
      return 0;
    }
  }
  
  #
  # build search xml message
  #

  $result =  "<searchRequest";
  
  # Load Process ID
  if ( $opt->{id} )
  {
     $result .= $reqID . (ref($opt->{id}) ? ${$opt->{id}} : $opt->{id}) . "\"";
  }
  elsif ( $ops{$id}->{pid} )
  {
     $result .= $ops{$id}->{pid};
     delete($ops{$id}->{pid});
  }
  else
  {
     $result .= $reqID . $pid{$id}->{pid} . "\"";
     ++$pid{$id}->{pid};
  }

  $result .= " dn=" . $ops{$id}->{sbase} . $ops{$id}->{scope} . $ops{$id}->{derefAliases} . $ops{$id}->{timelimit} . $ops{$id}->{sizelimit} . $ops{$id}->{typesOnly};
  #
  # Now add the filter xml string
  #
  $result .= $opt->{sfilter};

  #
  # Now add the attribute list as a xml string.
  #
  $result .= "<attributes>";

  for (my $i = 0; $i < $count; $i++)
  {
    $result .= "<attribute name=\"";
    $result .= ${$opt->{attributes}}[$i];
    $result .= "\"/>";
  }

  $result .= "</attributes>";
  $result .= $opt->{control} if ( defined($opt->{control}));
  $result .= $postSearch;
  push(@{$operations{$id}},$result);
  return 1;
}

# Method compare
# 
# The method compare compares  the dsml server for the requested information.
# 
# There are three required input options.
# Input option "dn": The dn of the object that you wish to do the comparsion on 
# Input option "attribute":  attributes to compare the value of.
# Input option "value":  value to compare against.
# 
# There are two option input options.
# Input option "id":  The request ID for this operation.
# Input option "control":  A Net::DSML::Control object.
# 
# $return = $dsml->compare( { dn => "cn=Super Man,ou=People,dc=xyz,dc=com", attibute => "sn", value => "manager" } );
# $return = $dsml->send();  # Post the xml message to the DSML server
# $content = $dsml->content(); # Get the data returned from the DSML server.
# 
# Method output;  Returns 1 (true) on success;  0 (false) on error, error 
# message can be gotten with error method.
# 
# The user must parse the returned xml content message to determine what the 
# dsml server responded with.
# 

sub compare
{
  my ($dsml, $opt) = @_;
  my $size;
  my $count;
  my $id = ident $dsml;
  my $result;
  my $dn;
  my $attribute;
  my $value;

  $dn = (ref($opt->{dn}) ? ${$opt->{dn}} : $opt->{dn});
  $attribute = (ref($opt->{attribute}) ? ${$opt->{attribute}} : $opt->{attribute});
  $value = (ref($opt->{value}) ? ${$opt->{value}} : $opt->{value});
  if ( !(length($dn)) )
  {
    $errMsg{$id} = "Subroutine compare dn value is not defined.";
    return 0;
  }

  if ( !(length($attribute)) )
  {
    $errMsg{$id} = "Subroutine compare attribute is not defined.";
    return 0;
  }

  if ( !(length($value)) )
  {
    $errMsg{$id} = "Subroutine compare attribute value is not defined.";
    return 0;
  }

  _specialChar(\$value) if ( $value =~ /(&||<||>||"||')/);

  $result =  "<compareRequest";

  # Load Process ID
 
  if ( $opt->{id} )
  {
     $result .= $reqID . (ref($opt->{id}) ? ${$opt->{id}} : $opt->{id}) . "\"";
  }
  elsif ( $ops{$id}->{pid} )
  {
     $result .= $ops{$id}->{pid};
     delete($ops{$id}->{pid});
  }
  else
  {
     $result .= $reqID . $pid{$id}->{pid} . "\"";
     ++$pid{$id}->{pid};
  }

  $result .= " dn=\"" . $dn . "\"><assertion name=\"" . $attribute . "\"><value>" . $value;

  $result .= $postCompare;
  $result .= $opt->{control} if ( defined($opt->{control}));
  $result .= "</compareRequest>";
  push(@{$operations{$id}},$result);
  return 1;
}


# Method delete
# 
# The method delete deletes an entry from the directory server.
# 
# There is one required input option.
# Input option "dn": The dn of the entry that you wish to delete.
# There are two optional input options.
# Input option "control": The control object to be used with the delete 
# operation. 
# Input option "id":  The request ID for this operation.
# 
# $return = $dsml->delete( { dn => "cn=Super Man,ou=People,dc=xyz,dc=com" } );
# $return = $dsml->send();  # Post the xml message to the DSML server
# $content = $dsml->content(); # Get the data returned from the DSML server.
# 
# Method output;  Returns 1 (true) on success;  0 (false) on error, error 
# message can be gotten with error method.
# 
# The user must parse the returned xml content message to determine what the 
# dsml server responded with.
# 

sub delete
{
  my ($dsml, $opt) = @_;
  my $size;
  my $count;
  my $id = ident $dsml;
  my $result;
  my $refvalue;
  $errMsg{$id} ="";
  $refvalue = (ref($opt->{dn}) ? ${$opt->{dn}} : $opt->{dn});
  if ( !(length($refvalue)) )
  {
    $errMsg{$id} = "Subroutine delete dn value is not defined.";
    return 0;
  }

  if (defined($opt->{control}))
  {
     $result  = "<delRequest";

     # Load Process ID

     if ( $ops{$id}->{pid} )
     {
        $result .= $ops{$id}->{pid};
        delete($ops{$id}->{pid});
     }
     else
     {
        $result .= $reqID . $pid{$id}->{pid} . "\"";
        ++$pid{$id}->{pid};
     }

     $result .= " dn=\"" . $refvalue . "\" >";
     $result .= $opt->{control};
     $result .= "</delRequest>";
  }
  else
  {
     $result = "<delRequest";

     # Load Process ID

     if ( $opt->{id} )
     {
        $result .= $reqID . (ref($opt->{id}) ? ${$opt->{id}} : $opt->{id}) . "\"";
     }
     elsif ( $ops{$id}->{pid} )
     {
        $result .= $ops{$id}->{pid};
        delete($ops{$id}->{pid});
     }
     else
     {
        $result .= $reqID . $pid{$id}->{pid} . "\"";
        ++$pid{$id}->{pid};
     }

     $result .= " dn=\"" . $refvalue . "\" />";
  }

  push(@{$operations{$id}},$result);
  return 1;
}


# Method modrdn
# 
# The method modrdn renames an entry in the directory server.
# 
# There are three required input options.
# Input option "dn": The dn of the entry that you wish to delete.
# Input option "newsuperior": The base dn of the entry that you wish to rename.
# Input option "newrdn": The rdn of the new entry that you wish to create.
# There are three optional input options.
# Input option "deleteoldrdn": The flag that controls the deleting of the 
# entry:  true -> delete entry, false -> keep entry.
# Input option "id":  The request ID for this operation.
# Input option "control": A Net::DSML::Control object output.
# 
# $return = $dsml->modrdn( { dn => "cn=Super Man,ou=People,dc=xyz,dc=com",
#                            newrdn => "cn=Bad Boy",
#                            deleteoldrdn => "true",
#                            newsuperior => "ou=People,dc=xyz,dc=com" } );
# $return = $dsml->send();  # Post the xml message to the DSML server
# $content = $dsml->content(); # Get the data returned from the DSML server.
# 
# Method output;  Returns 1 (true) on success;  0 (false) on error, error 
# message can be gotten with error method.
# 
# The user must parse the returned xml content message to determine what the 
# dsml server responded with.
# 

sub modrdn
{
  my ($dsml, $opt) = @_;
  my $size;
  my $count;
  my $id = ident $dsml;
  my $result;
  my $dn;
  my $newrdn;
  my $newsuperior;
  my $refvalue;

  $errMsg{$id} ="";

  $dn = (ref($opt->{dn}) ? ${$opt->{dn}} : $opt->{dn});
  $newrdn = (ref($opt->{newrdn}) ? ${$opt->{newrdn}} : $opt->{newrdn});
  $newsuperior = (ref($opt->{newsuperior}) ? ${$opt->{newsuperior}} : $opt->{newsuperior});
  $refvalue = (ref($opt->{deleteoldrdn}) ? ${$opt->{deleteoldrdn}} : $opt->{deleteoldrdn}) if ( $opt->{deleteoldrdn} );

  if ( !(length($dn)) )
  {
    $errMsg{$id} = "Subroutine modrdn dn value is not defined.";
    return 0;
  }

  if ( !(length($newrdn)) )
  {
    $errMsg{$id} = "Subroutine modrdn newrdn value is not defined.";
    return 0;
  }

  if ( !(length($newsuperior)) )
  {
    $errMsg{$id} = "Subroutine modrdn newsuperior value is not defined.";
    return 0;
  }

  $result  = "<modDNRequest";

  # Load Process ID

  if ( $opt->{id} )
  {
     $result .= $reqID . (ref($opt->{id}) ? ${$opt->{id}} : $opt->{id}) . "\"";
  }
  elsif ( $ops{$id}->{pid} )
  {
     $result .= $ops{$id}->{pid};
     delete($ops{$id}->{pid});
  }
  else
  {
     $result .= $reqID . $pid{$id}->{pid} . "\"";
     ++$pid{$id}->{pid};
  }

  $result .= " dn=\"" . $dn . "\" ";
  $result .= "newrdn=\"" . $newrdn . "\" ";
  $result .= "newSuperior=\"" . $newsuperior . "\" ";
  $result .= "deleteoldrdn=\"" . $refvalue . "\"" if ( $opt->{deleteoldrdn} );
  $result .= ">";
  $result .= $opt->{control} if ( defined($opt->{control}));
  $result .= "</modDNRequest>";

  push(@{$operations{$id}},$result);
  return 1;
}

#
# Method add
# 
# The method add adds an entry into the directory server.
# 
# There are 2 required input options.
# Input option "dn": The dn of the entry that you wish to add.
# Input option "attr": A hash of the attributes and their values that are
#                      that are to be in the entry.
#
# There are two optional input options.
# Input option "control": A Net::DSML::Control object output.
# Input option "id":  The request ID for this operation.
#
#
# $result = $dsml->add( { dn => 'cn=Barbara Jensen, o=University of Michigan, c=US',
#                         attr => {
#                                 'cn'   => ['Barbara Jensen', 'Barbs Jensen'],
#                                 'sn'   => 'Jensen',
#                                 'mail' => 'b.jensen@umich.edu',
#                                 'objectclass' => ['top', 'person',
#                                                   'organizationalPerson',
#                                                   'inetOrgPerson' ],
#                                 }
#                        }
#                        );
#
# $return = $dsml->send();  # Post the xml message to the DSML server
# $content = $dsml->content(); # Get the data returned from the DSML server.
# 
# Method output;  Returns 1 (true) on success;  0 (false) on error, error 
# message can be gotten with error method.
# 
# The user must parse the returned xml content message to determine what the 
# dsml server responded with.
# 

sub add
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $result;
  my @attributes;
  my $dn;
  $errMsg{$id} = "";

  $dn = (ref($opt->{dn}) ? ${$opt->{dn}} : $opt->{dn});

  if ( !(length($dn)) )
  {
    $errMsg{$id} = "Subroutine add dn value is not defined.";
    return 0;
  }

  @attributes = sort(keys(%{$opt->{attr}}));

  #
  # build search xml message
  #

  $result =  "<addRequest";
  
  # Load Process ID
  
  if ( $opt->{id} )
  {
     $result .= $reqID . (ref($opt->{id}) ? ${$opt->{id}} : $opt->{id}) . "\"";
  }
  elsif ( $ops{$id}->{pid} )
  {
     $result .= $ops{$id}->{pid};
     delete($ops{$id}->{pid});
  }
  else
  {
     $result .= $reqID . $pid{$id}->{pid} . "\"";
     ++$pid{$id}->{pid};
  }

  $result .= " dn=\"" . $dn . "\">";

  #
  # Now add the attribute list as a xml string.
  #

  foreach my $i (@attributes)
  {
    if ( ref($opt->{attr}{$i}))
    {
       if (ref($opt->{attr}{$i}) eq 'SCALAR')
       {
         $result .= "<attr name=\"$i\"><value>${$opt->{attr}{$i}}</value></attr>";
       }
       elsif (ref($opt->{attr}{$i}) eq 'ARRAY')
       {
         foreach my $val ( @{$opt->{attr}{$i}})
         {
         $result .= "<attr name=\"$i\"><value>$val</value></attr>";
         }

       }
       else 
       {
          $errMsg{$id} = "Invalid object in add subroutine attr hash.";
          return 0;
       }
    }
    else
    {
       $result .= "<attr name=\"$i\"><value>$opt->{attr}{$i}</value></attr>";
    }
  }

  $result .= $opt->{control} if ( defined($opt->{control}));
  $result .= "</addRequest>";
  push(@{$operations{$id}},$result);
  return 1;
}


#
# Method modify
# 
# The method modify modifies attributes in an entry.
# 
# There are 2 required input options.
# Input option "dn": The dn of the entry that you wish to add.
# Input option "attr": A hash of the attributes and their values that are
#                      that are to be in the entry.
#
# There are two optional input option.
# Input option "control": A Net::DSML::Control object output.
# Input option "id":  The request ID for this operation.
#
#
# $result = $dsml->modify( { 
#            dn => 'cn=Barbara Jensen, o=University of Michigan, c=US',
#            modify => {
#                       add => {
#                       'telephoneNumber' => ['214-972-1212','972-123-0987'],
#                              },
#                       replace => {
#                                 'mail' => 'barbara.jensen@umich.edu',
#                                  },
#                       delete => {
#                                 'cn'   => 'Barbs Jensen',
#                                 'title'   => '',
#                                  }
#                        } } );
#
# $return = $dsml->send();  # Post the xml message to the DSML server
# $content = $dsml->content(); # Get the data returned from the DSML server.
# 
# Method output;  Returns 1 (true) on success;  0 (false) on error, error 
# message can be gotten with error method.
# 
# The user must parse the returned xml content message to determine what the 
# dsml server responded with.
# 

sub modify
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $result;
  my @changes;
  my @action;
  my @attributes;
  my $dn;
  $errMsg{$id} = "";

  $dn = (ref($opt->{dn}) ? ${$opt->{dn}} : $opt->{dn});
  if ( !(length($dn)) )
  {
    $errMsg{$id} = "Subroutine modify dn value is not defined.";
    return 0;
  }


  @changes = sort(keys(%{$opt->{modify}}));

  #
  # build search xml message
  #

  $result =  "<modifyRequest";
  
  # Load Process ID
  
  if ( $opt->{id} )
  {
     $result .= $reqID . (ref($opt->{id}) ? ${$opt->{id}} : $opt->{id}) . "\"";
  }
  elsif ( $ops{$id}->{pid} )
  {
     $result .= $ops{$id}->{pid};
     delete($ops{$id}->{pid});
  }
  else
  {
     $result .= $reqID . $pid{$id}->{pid} . "\"";
     ++$pid{$id}->{pid};
  }

  $result .= " dn=\"" . $dn . "\">";

  #
  # Now add the attribute list as a xml string.
  #

  foreach my $action (@changes)
  {

    @action = sort(keys(%{$opt->{modify}{$action}}));
    foreach my $i ( @action)
    {

      if ( ref($opt->{modify}{$action}{$i}))
      {
         if (ref($opt->{modify}{$action}{$i}) eq 'SCALAR')
         {
           if ( !(length(${$opt->{modify}{$action}{$i}})))
           {
              $result .= "<modification name=\"$i\" operation=\"$action\"></modification>";
           }
           else
           {
              $result .= "<modification name=\"$i\" operation=\"$action\"><value>${$opt->{modify}{$action}{$i}}</value></modification>";
           }
         }
         elsif (ref($opt->{modify}{$action}{$i}) eq 'ARRAY')
         {
           $result .= "<modification name=\"$i\" operation=\"$action\">";
           foreach my $val ( @{$opt->{modify}{$action}{$i}})
           {
             if ( length($val))
             {
                $result .= "<value>$val</value>";
             }
           }
           $result .= "</modification>";
  
         }
         else 
         {
            $errMsg{$id} = "Invalid object in add subroutine modify hash.";
            return 0;
         }
      }
      else
      {
         $result .= "<modification name=\"$i\" operation=\"$action\">";
         if ( length($opt->{modify}{$action}{$i}))
         {
           $result .= "<value>$opt->{modify}{$action}{$i}</value>";
         }
         $result .= "</modification>";
      }

    }
  }

  $result .= $opt->{control} if ( defined($opt->{control}));
  $result .= "</modifyRequest>";
  push(@{$operations{$id}},$result);
  return 1;

}

#
# Method abandon
# 
# The method abandon request that the DSML server abandon the 
# batch request with the given ID.
# 
# There is 1 required input option.
# Input option "id": The id of the batch request to abandon.
#                    This id may be referenced.
#
#
# $result = $dsml->abandon( { id => $id } );
#
# $return = $dsml->send();  # Post the xml message to the DSML server
# $content = $dsml->content(); # Get the data returned from the DSML server.
# 
# Method output;  Returns 1 (true) on success;  0 (false) on error, error 
# message can be gotten with error method.
# 
# The user must parse the returned xml content message to determine what the 
# dsml server responded with.
# 

sub abandon
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $result;
  my $aid;
  $errMsg{$id} = "";

  $aid = (ref($opt->{id}) ? ${$opt->{id}} : $opt->{id});
  if ( !$id )
  {
    $errMsg{$id} = "Method abandon id value is not defined.";
    return 0;
  }

  $result = "<abandonRequest abandonID=\"$aid\">";
  $result .= "</abandonRequest>";
  push(@{$operations{$id}},$result);
  return 1;

}

#
#  This method is used mainly for debugging purposes.
#

sub getOperations
{
  my ($dsml) = @_;
  my $id = ident $dsml;
  my $data;

  $data = "";
  #
  # load each operation into the xml string in order.
  #
  foreach my $str (@{$operations{$id}})
  {
      $data .= $str;
  }
   
  return $data;
}

# Method getPostData
# 
# The method getPostData the xml data string that was posted to the
# DSML server.   It is used mainly for debugging problems.
#
# There are no required input options.
# 
# $content = $dsml->getPostData();
# 
# Method output;  Always returns 1 (true).
# 
# The user must parse the returned xml content message to determine what 
# was posted to the dsml server.
# 

sub getPostData
{
  my ($dsml) = @_;
  my $id = ident $dsml;

  return $postData{$id};
}

# Method send
# 
# The method send sends the xml data string that was created to the
# DSML server.   
#
# There are no required input options.
# 
# $result = $dsml->send();
# $content = $dsml->content(); # Get the data returned from the DSML server.
# 
# Method output;  Returns 1 (true) on success;  0 (false) on error, error 
# message can be gotten with error method.  This error code is from the 
# http process and NOT the DSML process
# 
# The user must parse the returned xml content message to determine what 
# was recieved from the dsml server.
# 

sub send
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $size;

  $size = @{$operations{$id}};
  if ( !$size )
  {
    $errMsg{$id} = "No XML query data string present.";
    return 0;
  }

  # start xml string 
  $postData{$id} = $postHead . $preBatch . $ops{$id}->{reqid} . $ops{$id}->{onerror} . $ops{$id}->{responseOrder} . $ops{$id}->{processing} . ">";
  
  $postData{$id} .= $ops{$id}->{auth} if ( length($ops{$id}->{auth}));

  #
  # load each operation into the xml string in order.
  #
  foreach my $str (@{$operations{$id}})
  {
      $postData{$id} .= $str;
  }
  
  # terminate the xml string.
  $postData{$id} .= $postBatch .  $postTail;
  if ( !defined($opt->{debug}))
  {
    return $dsml->_post();   # Send the data to the dsml server.
  }
  else
  {
    return 1;
  }
}

# 
#  This version of the method post uses a XML string
#  that has been built prior to calling this method.
# 
# <returns>true on success, false on error. </returns>
# <remarks>Use errMsg method to get error message.</remarks> 
#
sub _post
{
  my $dsml = shift;
  my $id = ident $dsml;

  if (length($postData{$id}) == 0 )
  {
    $errMsg{$id} = "No XML query data string present.";
    return 0;
  }

  return $dsml->_postit();
}

#
#
#  The private method postit executes the HTTP DSML request.
#
# true on success, false on error. 
# Use errMsg method to get error message. 
#
sub _postit
{
  my $dsml = shift;
  my $ua;
  my $headers;
  my $req;
  my $res;
  my $psize;
  my $host;
  my $dsmlinfo;
  my $postData;
  my $uriString;
  my $code;

  my $id = ident $dsml;

  $psize{$id} = length($postData{$id});
  $psize = length($postData{$id});
  $uriString = $ops{$id}->{host};
  $postData = $postData{$id};
  $prepostData{$id} = $postData;  # Copy of actual postData

  $ua = new LWP::UserAgent;
  $ua->agent('DSML HTTP/1.1');
  print $postData if ( $ops{$id}->{debug} );

  $headers = HTTP::Headers->new( 'content-length' => $psize,
                                 'HOST'  => $uriString,
                                 'SOAPAction'  => "",
                                 'Content-Type'  => "text/xml",
                                 'Connection'  => "close");

  $headers->authorization_basic($authentication{$id}->{dn}, $authentication{$id}->{password} ) if ( $authentication{$id} );
  #
  # Create the request
  #
  $req =  new HTTP::Request ('POST',$uriString, $headers);
  $req->content($postData);
  $res = $ua->request($req);

  
  #
  # Check the outcome of the response
  #
  if ($res->is_success)
  {
    print "Success\n" if ( $ops{$id}->{debug});    
    $content{$id} =  $res->content;
  }
  else
  {
    print "No Success\n" if ( $ops{$id}->{debug});    
    $code = $res->status_line;
    $errMsg{$id} = "$code";
    return 0;
  }

  if (length($content{$id}) == 0  )
  {
#       print "No Success return\n";    
    $errMsg{$id} = "Error, no response data received from " . $uriString . ".";
    return 0;
  }
  $errMsg{$id} = "";   # Clear the error message string.
  return 1;   # Exit the method with no errors, does not mean we got data!
}

}

1; # Magic true value required at end of module

__END__

=head1 NAME

Net::DSML -  A perl module that supplies methods for connecting to a LDAP Directory Services Markup Language (DSML) server.


=head1 VERSION

This document describes Net::DSML version 0.003


=head1 SYNOPSIS

 Search example.
 
 # Search for entry in the directory server.
 # 
 use Net::DSML;
 use Net::DSML::Filter;
 use Net::DSML::Control;

 # Create a filter object.
 $filter = Net::DSML::Filter->new();
 # Create a subString filter
 if ( !($webfilter->subString( { type =>"initial", 
                                 attribute => $attribute, 
                                 value => $value } ) ) )
 {
    print $filter->error(), "\n";
    exit;
 }

 # Create a Control object, sort control
 $webcontrol->new( { control => "1.2.840.113556.1.4.473" } );

 # Create a DSML object.
 $dsml = Net::DSML->new({ debug => 0, 
                         url => "http://system.company.com:8080/dsml" });
 # Set the batch ID
 $dsml->setBatchId( { id => "1" } );

 if ( !( $dsml->search( { sfilter => $webfilter->getFilter(), 
                          attributes => \@attributes,
                          base => $base,
                          control => $webcontrol->getControl() } ) ) )
(
    print $dsml->error, "\n";
    exit;
 }
 # Post the xml message to the DSML server
 if ( !$dsml->send() )
 (
    print $dsml->error, "\n";
    exit;
 }
 
 # Get the xml data returned from the DSML server.
 $content = $dsml->content(); # Get data returned from the DSML server.

 # The user then uses the xml parser if their choice to break down
 # the returned xml message.


 Search example with HTTP Basic authenication.
 
 # Search for entry in the directory server.
 # 
 use Net::DSML;
 use Net::DSML::Filter;
 use Net::DSML::Control;

 # Create a filter object.
 $filter = Net::DSML::Filter->new();
 # Create a subString filter
 if ( !($webfilter->subString( { type =>"initial", 
                                 attribute => $attribute, 
                                 value => $value } ) ) )
 {
    print $filter->error(), "\n";
    exit;
 }

 # Create a Control object, sort control
 $webcontrol->new( { control => "1.2.840.113556.1.4.473" } );

 # Create a DSML object.
 $dsml = Net::DSML->new({ debug => 0, 
                         url => "https://system.company.com:9090/dsml",
                         dn => "root",
                         password => "xxY123",
                         base => \$base });
 # Set the batch ID
 $dsml->setBatchId( { id => "1" } );

 if ( !( $dsml->search( { sfilter => $webfilter->getFilter(), 
                          attributes => \@attributes,
                          control => $webcontrol->getControl() } ) ) )
(
    print $dsml->error, "\n";
    exit;
 }
 # Post the xml message to the DSML server
 if ( !$dsml->send() )
 (
    print $dsml->error, "\n";
    exit;
 }
 
 # Get the xml data returned from the DSML server.
 $content = $dsml->content(); 

 # The user then uses the xml parser if their choice to break down
 # the returned xml message.

 RootDSE example.
 
 # Get rootDSE from the DSML directory server.
 # The rootDSE method will generate the correct filter for this
 # operation.
 use Net::DSML;
 use Net::DSML::filter;

 $dsml = Net::DSML->new({ debug => 1, 
                         url => "http://system.company.com:8080/dsml" });

 if ( !$dsml->rootDSE( { attributes => \@attributes } ) )
 (
    print $dsml->error, "\n";
    exit;
 }
 # Post the xml message to the DSML server
 if ( !$dsml->send() )
 (
    print $dsml->error, "\n";
    exit;
 }
 
 # Get the xml data returned from the DSML server.
 $content = $dsml->content(); # Get data returned from the DSML server.

 # The user then uses the xml parser if their choice to break down
 # the returned xml message.

There are other examples in the scripts that are in the module`s 
Examples directory and the module test files are good examples of 
using this module.

=head1 DESCRIPTION

Net::DSML is a collection of three modules that implements a LDAP
DSML API for Perl programs. The module may be used to
search for and modify a LDAP directory entry.

This document assumes that the reader has some knowledge of
the LDAP and DSML protocols.  Information regarding 
Directory Services Markup Language can be found at URL: 
L<http://www.oasis-open.org/specs/index.php#dsmlv2>

=head1 XML PARSER

B<This module does not parse the xml data returned from the DSML
server.  This is left up to the user, this allows the user to
use the xml parser of their choice.>

=head1 AUTHENICATION ISSUES

There are at least two ways of doing DSML authenication to a
LDAP directory server.

One way is with the DSML authRequest, which is used when the 
process is capable of proxy authorization.  This is the method that
is supported by the OASIS documentation, in the word document on 
page 10, section 5.1.

Another way is with HTTP authorization.  This process involes passing
a DN and password to the HTTP process and allowing the http process to
authenicate to the DSML server.  This process can be used by the
SUN One directory server ( Iplanet 5.2) and the Sun One Java Directory
Server (SUN`s version 6 directory server).  For this process to 
be allowed the dse.ldif file must be setup properly.

This software was tested using HTTP authorization.

=head1 CONSTRUCTOR

=over 1

=item B<new ( {OPTIONS} )>

The method new is the constructor for a new DSML oject.

Input options.

Authenication options.  These must be supplied in the object constructor.

Http authorization. 
 Input option "dn":  String that contains the DN. 
 Input option "password":  String that contains the password of the DN.

Proxy authorization.
 Input option "proxyid":  String that contains the proxy DN.

There are several possible general input options.

 Input option "base":  String that contains the LDAP search base.
 Input option "debug":  Sets the debug variable to the input value.
 Input option "error":  String that contains the LDAP onError value;
 exit or resume.  Default is exit.
 Input option "process":  String that contains the LDAP process value;
 sequential or parallel.  Default is sequential.
 Input option "order":  String that contains the LDAP order value;
 sequential or unordered.  Default is sequential.
 Input option "referral":  String that contains the referral control
 value; neverDerefAliases, derefInSearching, derefFindingBaseObj 
 or derefAlways.  Default is neverDerefAliases.
 Input option "scope":  String that contains the LDAP scope value;
 singleLevel, baseObject or wholeSubtree.  Default is singleLevel.
 Input option "size":  String that contains the size limit of the
 LDAP search.  Default is "0", unlimited.
 Input option "time":  String that contains the time limit of the
 LDAP search.  Default is "0", unlimited.
 Input option "type":  String that contains the LDAP scope value;
 true or false.  Default is false.
 Input option "url":    Specifies the LDAP server to connect to.

Examples;
 $dsml = Net::DSML->new({ debug => 1, 
                         url => "http://system.company.com:8080/dsml" });

Method output;  Returns a new DSML object.
Method error;  If there is an error message then there was an error in
object creation, the error message can be gotten with error method.

=back

=head1 METHODS

=over 1

=item B<setScope ( {OPTIONS} )>

The method setScope sets the LDAP search scope.

There is one required input option.

 Input option "scope":  String that contains the LDAP scope value; 
 singleLevel, baseObject or wholeSubtree.  Default is singleLevel.

 $return = $dsml->setScope( { scope => "singleLevel" } );

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.

=item B<setReferral ( {OPTIONS} )>

The method setReferral sets the LDAP referral status.

There is one required input option.

Input option "referral":  String that contains the referral control value; 
neverDerefAliases, derefInSearching, derefFindingBaseObj or derefAlways. 
Default is neverDerefAliases.

 $return = $dsml->setReferral( { referral => "neverDerefAliases" } );

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.

=item B<setType ( {OPTIONS} )>

The method setType sets the LDAP search scope.

There is one required input option.

 Input option "type":  String that contains the LDAP scope value; 
 true or false.  Default is false.

 $return = $dsml->setType( { type => "false" } );

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.

=item B<setSize ( {OPTIONS} )>

The method setSize sets the size limit of the LDAP search.

There is one required input option.

 Input option "size":  String that contains the size limit of the 
 LDAP search.  Default is "0".

 $return = $dsml->setSize( { size => 0 } );

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.


=item B<setTime ( {OPTIONS} )>

The method setTime sets the time limit of the LDAP search.

There is one required input option.

 Input option "time":  String that contains the time limit of the
 LDAP search.  Default is "0".

 $return = $dsml->setTime( { time => "0" } );

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.


=item B<setOrder ( {OPTIONS} )>

The method setOrder sets the order of the returned  LDAP data.

There is one required input option.

 Input option "order":  String that contains the LDAP order value; 
 sequential or unordered.  Default is sequential.

 $return = $dsml->setOrder( { order => "sequential" } );

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.


=item B<setProcess ( {OPTIONS} )>

The method setProcess sets the LDAP DSML processing mode; sequential 
or parallel.  If you use parallel you must set up a seperate unique 
requestId for each requested chunk of data.

There is one required input option.

 Input option "process":  String that contains the LDAP process 
 value; sequential or parallel.  Default is sequential.

 $return = $dsml->setProcess( { process => "sequential" } );

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.


=item B<setOnError ( {OPTIONS} )>

The method setOnError sets the LDAP DSML processing mode for errors; exit 
or resume.  

There is one required input option.

 Input option "error":  String that contains the LDAP onError 
 value; exit or resume.  Default is exit.

 $return = $dsml->setOnError( { error => "exit" } );

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.


=item B<setBatchId ( {OPTIONS} )>

The method setBatchId sets the batch request id.

There is one required input option.

 Input option "id":  String that contains the LDAP operation 
 request id. Default is "batch request".

 $return = $dsml->setBatchId(  { id => "batch request" });

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.

=item B<setProcessId ( {OPTIONS} )>

The method setProcessId sets the LDAP process operation request id.
Very important method if parallel processing is enabled because each
parallel operation must have a unique request id.

There is one required input option.

 Input option "id":  String that contains the LDAP process operation 
 request id.  Default value: 1, incremented after each process.


 $return = $dsml->setProcessId(  { id => "process id" });

Method output;  Returns true on success;  false on error, error message
can be gotten with error method.



=item B<setBase ( {OPTIONS} )>

The method setBase sets the LDAP search base.
This is a required method, program must set it.

There is one required input option.

 Input option "base":  String that contains the LDAP search base.

 $return = $dsml->setBase( { base => "dc=company,dc=com" } );

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.


=item B<debug ( {OPTIONS} )>

The method debug sets or returns the object debug flag.

There is one input option.

 Input option:  Debug value; 1 or 0.  Default is 0.

 $return = $dsml->debug( 1 );

Method output; Returns debug value.


=item B<url ( OPTIONS )>

The method url sets or returns the object url value.

There is one required input option.

 Input option:  Host system name.

 $return = $dsml->url( "http://xyz.company.com:8080/dsml" );

Method output; Returns host value.


=item B<error ()>

The method error returns the error message for the object.
 $message = $dsml->error();


=item B<size ()>

The method size returns the size of the last dsml message sent to the dsml 
server.

$size = $dsml->size();


=item B<content ()>

The method content returns the last dsml message received from the dsml server.
Once the user has the content he or she can use whatever XML parser they
choose.

 $returnXmlMessage = $dsml->content();

 
=item B<setProxy ( {OPTIONS} )>

The method setProxy sets the LDAP authenication dn.

There is one required input option.

 Input option "dn":  String that contains the LDAP authenication dn.

 $return = $dsml->setProxy( { dn => "cn=directory manager" } );

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.  Errors will pretain to 
input options.


=item B<search ( {OPTIONS} )>

The method search searchs the dsml server for the requested information.

There are two required input options.

 Input option "sfilter":  The filter object that contains the filter 
 string.
 Input option "attributes":  Reference to an array of attributes to get 
 information on.

There are three optional input options.
 Input option "id":  The request ID for this operation.
 Input option "control": A Net::DSML::Control object output.
 Input option "base": The search base dn.

 $return = $dsml->search( { sfilter => $dsml->getFilter(), 
                            id => 234,
                            base => "ou=people,dc=yourcompany,dc=com",
                            control => $dsmlControl->getControl(),
                            attributes => \@attributes } );
 # Post the message to the DSML server
 $return = $dsml->send();
 # Get data returned from the DSML server.
 $content = $dsml->content(); 

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.   Errors will pretain to 
input options.

=item B<add ( {OPTIONS} )>

The method add adds an entry into the directory server.

In order to use the add method properly, the command must do a bind to 
directory server.  This done with the http authenication process or with
the authRequest proxy dn.

There are 2 required input options.
 Input option "dn": The dn of the entry that you wish to add.
 Input option "attr": A hash of the attributes and their values that are
                      that are to be in the entry.

There are two optional input option.
 Input option "control": A Net::DSML::Control object output.
 Input option "id":  The request ID for this operation.

Example using the http authenication process.
 
 $dsml = Net::DSML->new( { url => $server, 
                           id => "999", 
                           dn => "xxx", 
                           passw ord => "xxx"
                         } 
                       );


 $result = $dsml->add( { 
           dn => 'cn=Barbara Jensen, o=University of Michigan, c=US',
           attr => {
                    'cn'   => ['Barbara Jensen', 'Barbs Jensen'],
                    'sn'   => 'Jensen',
                    'mail' => 'b.jensen@umich.edu',
                    'objectclass' => ['top', 'person',
                                      'organizationalPerson',
                                      'inetOrgPerson' ],
                    } } );

 # Post the xml message to the DSML server
 $return = $dsml->send();  
 # Get the data returned from the DSML server.
 $content = $dsml->content(); 


Example using the authRequest (proxy) process.
 
 $dsml = Net::DSML->new( { url => $server });

 $dsml->setProxy( { dn => "uid=root,ou=proxies,dc=company,dc=com");

 $result = $dsml->add( { 
           dn => 'cn=Barbara Jensen, o=University of Michigan, c=US',
           attr => {
                    'cn'   => ['Barbara Jensen', 'Barbs Jensen'],
                    'sn'   => 'Jensen',
                    'mail' => \$mail,
                    'objectclass' => ['top', 'person',
                                      'organizationalPerson',
                                      'inetOrgPerson' ],
                   } } );

 # Post the xml message to the DSML server
 $return = $dsml->send();
 # Get the data returned from the DSML server.
 $content = $dsml->content();

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.

The user must parse the returned xml content message to determine what the 
dsml server responded with.

=item B<modify  ( {OPTIONS} )>

The method modify modifies attributes in an entry.

In order to use the modify method properly, the command must do a bind to 
directory server.  This done with the http authenication process or with
the authRequest proxy dn.  This process is explained in the method add 
documentation.
 
There are 2 required input options.
 Input option "dn": The dn of the entry that you wish to add.
 Input option "modify": A hash of the attributes and their values that are
                       that are to be in the entry.

There are two optional input option.
 Input option "control": A Net::DSML::Control object output.
 Input option "id":  The request ID for this operation.

 $result = $dsml->modify( { 
            dn => 'cn=Barbara Jensen, o=University of Michigan, c=US',
            modify => {
                       add => {
                       'telephoneNumber' => ['214-972-1212',
                                             '972-123-0987'],
                              },
                       replace => {
                                 'mail' => \$mail,
                                  },
                       delete => {
                                 'cn'   => 'Barbs Jensen',
                                 'title'   => '',
                                  }
                        } } );

 # Post the xml message to the DSML server
 $return = $dsml->send();
 # Get the data returned from the DSML server.
 $content = $dsml->content();
 
Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.
 
The user must parse the returned xml content message to determine what the 
dsml server responded with.

=item B<compare ( {OPTIONS} )>

The method compare, compares a specified value to a value in an 
attibute in the specified DN.

In order to use the compare method properly on some attributes, the 
command must do a bind to directory server.  This done with the 
http authenication process or with the authRequest proxy dn.  This 
process is explained in the method add documentation.

There are three required input options.

 Input option "dn": The dn of the entry that you wish to do the 
 comparsion on.
 Input option "attribute":  attribute to compare.
 Input option "value":  value to compare against.

There are 2 optional input options.
 Input option "control": A Net::DSML::Control object output.
 Input option "id":  The request ID for this operation.
 
 $return = $dsml->compare( { dn => "cn=Man,ou=People,dc=xyz,dc=com", 
                             attibute => "sn", 
                             id => 123, 
                             value => "manager" } );
 # Post the xml message to the DSML server
 $return = $dsml->send();
 # Get the data returned from the DSML server.
 $content = $dsml->content();

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.   Errors will pretain to 
input options.

The user must parse the returned xml content message to determine what the 
dsml server responded with.

=item B<delete ({OPTIONS}) >
 
The method delete deletes an entry from the directory server.

In order to use the delete method properly, the command must do a bind to 
directory server.  This done with the http authenication process or with
the authRequest proxy dn.  This process is explained in the method add 
documentation.
 
There is one required input option.
 Input option "dn": The dn of the entry that you wish to delete.
 
There is one optional input option.
 Input option "control": A Net::DSML::Control object output.
 Input option "id":  The request ID for this operation.

 $return = $dsml->delete( { 
                  dn => "cn=Super Man,ou=People,dc=xyz,dc=com",
                  id => 1 } );
 # Post the xml message to the DSML server
 $return = $dsml->send();
 # Get the data returned from the DSML server.
 $content = $dsml->content();
 
Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.
 
The user must parse the returned xml content message to determine what the 
dsml server responded with.

=item B<modrdn ({OPTIONS})>

The method modrdn renames an entry in the directory server.

There are three required input options.
 Input option "dn": The dn of the entry that you wish to 
 delete.
 Input option "newsuperior": The base dn of the entry that 
 you wish to rename.
 Input option "newrdn": The rdn of the new entry that you 
 wish to create.

There are three optional input options.
 Input option "deleteoldrdn": The flag that controls the 
 deleting of the entry:  true or false.
 Input option "control": A Net::DSML::Control object output.
 Input option "id":  The request ID for this operation.

 $return = $dsml->modrdn( { 
            dn => "cn=Super Man,ou=People,dc=xyz,dc=com",
            newrdn => "cn=Bad Boy",
            deleteoldrdn => "true",
            newsuperior => "ou=People,dc=xyz,dc=com"
                          } );
 # Post the xml message to the DSML server
 $return = $dsml->send(); 
 # Get the data returned from the DSML server.
 $content = $dsml->content();

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.

The user must parse the returned xml content message to determine what the 
dsml server responded with.

=item B<abandon ({OPTIONS})>

The method abandon request that the DSML server abandon the 
batch request with the given ID.
 
There is 1 required input option.
 Input option "id": The id of the batch request to abandon.
                    This id may be referenced.


 $result = $dsml->abandon( { id => $id } );

 $return = $dsml->send();  # Post the xml message to the DSML server
 $content = $dsml->content(); # Get the data returned from the DSML server.
 
Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.

The user must parse the returned xml content message to determine what the 
dsml server responded with.

=item B<Ping ()>

The method Ping Request to the dsml server.  A Ping requests
is use to confirm the existance of a dsml server on a 
system.

There are no inputs options for this method.

 $return = $dsml->Ping();
 # Post the xml message to the DSML server
 $return = $dsml->send();
 # Get the data returned from the DSML server.
 $content = $dsml->content();

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.   Errors will pretain to 
input options.

The user must parse the returned xml content message to determine if the 
dsml server responded.


=item B<rootDSE ( {OPTIONS} )>

The method DSE the searchs the root, or dse, of the dsml server. 

There is one required input option.

 Input option "attributes":  Refernce to an array of attributes to get 
 information on.

There is one optional input option.
 Input option "control": A Net::DSML::Control object output.

There is one optional input option.
 Input option "id":  The request ID for this operation.
 
 $return = $dsml->rootDSE( { id => 21, attributes => \@attributes } );
 $return = $dsml->send();  # Post the message to the DSML server
 $content = $dsml->content(); # Get data returned from the DSML server.

The scope will automatically be set to the correct value for the user.

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.  Errors will pretain to 
input options.

The user must parse the returned xml content message to determine what the 
dsml server responded with.

=item B<getOperations>

The method getOperations is used mainly by test operations.  It can
be used to get the operations list prior to using the send method.

=item B<getPostData>
 
The method getPostData the xml data string that was posted to the
DSML server.   It is used mainly for debugging problems.

There are no required input options.

 $content = $dsml->getPostData();

Method output;  Always returns 1 (true).

The user must parse the returned xml content message to determine what 
was posted to the dsml server.


=item B<send>

The method send sends the xml data string that was created to the
DSML server.   

There are no required input options.

 # Post the xml message to the DSML server
 $return = $dsml->send();
 # Get the data returned from the DSML server.
 $content = $dsml->content();

Method output;  Returns 1 (true) on success;  0 (false) on error, error 
message can be gotten with error method.  This error code is from the 
http (LWP) process and NOT the DSML process.

The user must parse the returned xml content message to determine what 
was recieved from the dsml server.

=back

=head1 DIAGNOSTICS

All of the error messages should be self explantory.


=head1 CONFIGURATION AND ENVIRONMENT

Net::DSML requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over 4

        Test::More          => 0
        version             => 0.680
        Readonly            => 1.030
        Class::Std::Utils   => 0.0.2
        LWP::UserAgent      => 2.0
        Carp                => 1.040

=back

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Currently there is a limition concerning authentication, it has
not yet been implemented.  This rules out any operations that 
modify data or access to data that requires authentication to 
access data.

No bugs have been reported.

Please report any bugs or feature requests to
charden@pobox.com, or C<bug-net-dsml@rt.cpan.org>, or through 
the web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Clif Harden  C<< <charden@pobox.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Clif Harden C<< <charden@pobox.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
