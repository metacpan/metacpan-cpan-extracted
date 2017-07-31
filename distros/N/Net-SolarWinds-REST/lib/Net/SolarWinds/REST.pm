package Net::SolarWinds::REST;

=head1 NAME

Net::SolarWinds::REST - SolarWinds Rest interface

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Net::SolarWinds::REST;
  use Data::Dumper;

  my $rest=new Net::SolarWinds::REST();

  my $result=$rest->DiscoverInterfacesOnNode(444);

  if($result) {
    print Dumper($result->get_data);
  } else {
    print $result,"\n";
  }

=head1 DESCRIPTION

Anyone who has used SOAP::Lite to try to interface with solarwinds knows how difficult and frustrating it can be.  This collection of modules provides a restful interface to SolarWinds.  Methods provided are tested and working in the Charter Communcations production enviroment.

=cut

use 5.010001;
use strict;
use warnings;
use Data::Dumper;
use IO::Socket::SSL;
use LWP::UserAgent;
use HTTP::Request;
use MIME::Base64 qw();
use Net::SolarWinds::Log;
use JSON qw();
use URI::Encode qw(uri_encode);
use POSIX qw(strftime);

our $VERSION="1.22";

use base qw(Net::SolarWinds::ConstructorHash Net::SolarWinds::LogMethods Net::SolarWinds::Helper);
use constant RESULT_CLASS=>'Net::SolarWinds::Result';
use constant TIMESTAMP_FORMAT=>'%m/%d/%Y %H:%M:%S';
use Net::SolarWinds::Result;


=head1 GLOBAL OBJECTS

=over 4

=item * $Net::SolarWinds::REST::JSON

This is a JSON object with the following options endabled: JSON->new->allow_nonref->utf8

=cut

# Global JSON OBJECT
our $JSON=JSON->new->allow_nonref->utf8;

=item * my $json=$class->get_json;

Returns the class level JSON object.

=cut

sub get_json { return $JSON; }

=item * $Net::SolarWinds::REST::UA

This is a LWP::UserAgent used to talk to CPM servers

=cut

# Global UA object
our $UA=LWP::UserAgent->new;
# Turn off SSL Verification
$UA->ssl_opts( 
  SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, 
  SSL_hostname => '', 
  verify_hostname => 0 
);


=item * my $ua=$class->get_ua;

Returns the Class level UA object.

=cut

sub get_ua { return $UA; }

=back

=cut

=head1 Class Constants

The following constants are accessable via: Net::SolarWinds::REST->CONSTANT

  DEFAULT_USER=>'admin';
  DEFAULT_PASS=>'ChangeMe';
  DEFAULT_SERVER=>'SolarWindsServer';
  DEFAULT_PORT=>17778;
  DEFAULT_PROTO=>'https';
  BASE_URI=>'%s://%s:%i/SolarWinds/InformationService/v3/Json/%s';
  LOG_CLASS=>'Net::SolarWinds::Log';

=cut

use constant DEFAULT_USER=>'admin';
use constant DEFAULT_PASS=>'ChangeMe';
use constant DEFAULT_SERVER=>'SolarWindsServer';
use constant DEFAULT_PORT=>17778;
use constant DEFAULT_PROTO=>'https';
use constant BASE_URI=>'%s://%s:%i/SolarWinds/InformationService/v3/Json/%s';
use constant LOG_CLASS=>'Net::SolarWinds::Log';

=head2 OO Methods

This section covers the OO Methods of the class.

=over 4

=item * Object Constructor.

The object constructor takes key=>value pairs all aguments are optional, default values are pulled from the constants DEFAULT_*.

  my $sw=new Net::SolarWinds::REST(
    USER   =>'User',
    PASS   =>'Passxxx',
    SERVER =>'SolarwindsServer',
    PORT   =>17778,
    PROTO  =>'https',
    # Logging is not enabled by default!
    log=>  Net::SolarWinds::Log->new('/var/log/Solarwinds.log')
  );

=cut

sub new {
  my ($class,%args)=@_;

  foreach my $key (qw(USER PASS SERVER PORT PROTO)) {
    my $method="DEFAULT_$key";
    next if exists $args{$key};
    $args{$key}=$class->$method;
  }
  
  my $self=$class->SUPER::new(%args);

  $self->{header}=[
    Authorization=>'Basic '.MIME::Base64::encode_base64($self->{USER} . ':' . $self->{PASS}),
    'Content-Type' => 'application/json',
  ];
  return $self;
}

=item * my $request=$self->build_request('GET|POST|PUT|DELETE',$path,undef|$ref);

Creates an HTTP::Request object with the default options set.

=cut

sub build_request {
  my ($self,$method,$path,$data)=@_;
  my $uri=sprintf $self->BASE_URI,@{$self}{qw(PROTO SERVER PORT )},$path;

  my $content=undef;
  my $headers=[@{$self->{header}}];
  if(defined($data)) {
    $content=$self->get_json->encode($data);
    push @{$headers},'Content-Length'=>length($content);
  }
  my $request=HTTP::Request->new($method,$uri,$headers,$content);
  $self->log_debug($request->as_string);
  return $request;
}

=item * my $request=$self->NodeUnmanage($nodeID,$start,$end,$state);

Used to manage and unmanage a node.

Optional Arguments:
  $start '11/18/2015 11:37:25'
  $end '11/20/2015 11:37:25'
  $state 
    To Manage: JSON::false
    To UnManage: JSON::true 

Default interal values are

  $start=now
  $end=now + 10 years
  $state=JSON::true

=cut
    
sub NodeUnmanage {
  my ($self,$nodeid,$start,$end,$state)=@_;
  my $id='N:'.$nodeid;

  $start=$self->now_timestamp unless defined($start);
  $end=$self->future_timestamp unless defined($end);
  $state=JSON::true unless defined($state);
  my $request=$self->build_request('POST','Invoke/Orion.Nodes/Unmanage',[$id,$start,$end,$state]);
  my $result=$self->run_request($request);

  return $result;
}

=item * my $now=$self->now_timestamp;

Returns a timestamp of now.

=cut

sub now_timestamp {
  my ($self)=@_;
  my $now=strftime($self->TIMESTAMP_FORMAT,localtime);
  return $now;
}

=item * my $future=$self->future_timestamp;

Returns a timestamp of 10 years for now ( plus or minus a few seconds )

=cut

sub future_timestamp {
  my ($self)=@_;
  my $now=time;
  # 10 years from now!
  $now +=60 * 60 * 24 * 365 * 10;
  my $ts=strftime($self->TIMESTAMP_FORMAT,localtime($now));
  return $ts;
}

=item * my $result=$self->run_request($request);

Takes a given HTTP::Request object and runs it returing a Net::SolarWinds::Result object.
What the object contains is relative to the request run..  If the result code of the request
was not a 20x value then the object is false.

=cut

sub run_request {
  my ($self,$request)=@_;

  $self->log_debug("Sending: ",$request->as_string);
  my $response=$self->get_ua->request($request);
  $self->log_debug("Got back",$response->as_string);
  my $content=$response->decoded_content;
  if($response->is_success) {
    if($content=~ /^\s*[\[\{]/s) {
      my $data=eval {$self->get_json->decode($content)};
      if($@) {
        return $self->RESULT_CLASS->new_false("Code: [".$response->code."] JSON Decode error [$@] Content:  $content",$response);
      } else {
        return $self->RESULT_CLASS->new_true($data,$response);
      }
    } else {
      return $self->RESULT_CLASS->new_true($content,$response);
    }
  } else {
    return $self->RESULT_CLASS->new_false("Code: [".$response->code."] http error [".$response->status_line."] Content:  $content",$response);
  }
}

=item * my $result=$self->DiscoverInterfacesOnNode($nodeId)

Returns a Net::SolarWinds::Result Object: When true it contains the results, when false it contains the error.

=cut

sub DiscoverInterfacesOnNode {
  my ($self,$nodeId)=@_;

  # force a string;
  $nodeId .='';

  $self->log_info("Started Discoverying interfaces on nodeid: $nodeId");
  my $request=$self->build_request('POST','Invoke/Orion.NPM.Interfaces/DiscoverInterfacesOnNode',[$nodeId]);
  my $result=$self->run_request($request);
  $self->log_info("Finished Discoverying interfaces on nodeid: $nodeId");

  return $result;
}

=item * my $result=$self->DiscoverInterfaceMap($nodeId);

Returns a Net::SolarWinds::Result object:

When true it contains an anonymous hash that maps interface objects to interface names.
When false it contains why it failed.

=cut

sub DiscoverInterfaceMap {
  my ($self,$node_id)=@_;

  $self->log_info("starting node_id: $node_id");
  my $result=$self->DiscoverInterfacesOnNode($node_id);
  $self->log_info("stopping");
  return $self->build_interface_result_map($result);
}

=item * my $result=$self->build_interface_result_map($result);

Internals of DiscoverInterfaceMap

=cut

sub build_interface_result_map {
  my ($self,$result)=@_;

  $self->log_info("starting");
  unless($result) {
    $self->log_error("failed to build interface map error was: $result");
    $self->log_info("stopping");
    return $result;
  }
  my $list=$result->get_data->{DiscoveredInterfaces};

  my $map={};
  foreach my $int (@{$list}) {
     my $caption=$int->{Caption};
     my @list=$self->InterfaceCaptionTranslation($caption);
     foreach my $ifname (@list) {
       $map->{$ifname}=$int;
     }
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($map,$list);
}

=item * my @names=$self->InterfaceCaptionTranslation($Caption);

Takes an interface caption and converts it to a list of valid interface names that should match what is on a given device.

=cut

sub InterfaceCaptionTranslation {
  my ($self,$caption)=@_;

  $self->log_info("starting");
  my @list;
  if($caption=~ s/\s\\x\{b7\}.*$//s > 0) {
    push @list,$caption;
  } else {
    push @list,split /\s+-\s+/,$caption;
  }

  $self->log_info("stopping");
  return @list;
}

=item * my $result=$self->NodeInterfaceAddDefaultPollers($nodeId,$interfaec_ref);

Returns a Net::SolarWinds::Result Object: When true it contains the results, when false it contains the error.
$interface_ref represents object listed from the DiscoverInterfacesOnNode that need to be added to the default pollers.

=cut

sub NodeInterfaceAddDefaultPollers {
  my ($self,$nodeId,$data)=@_;

  $self->log_info("starting");
  # force a string;
  $nodeId .='';
  
  my $request=$self->build_request('POST','Invoke/Orion.NPM.Interfaces/AddInterfacesOnNode',[$nodeId,$data,'AddDefaultPollers']);
  my $result=$self->run_request($request);

  $self->log_info("stopping");
  return $result;
}

=item * my $result=$self->NodeAddInterface($node_id,[$interface]);

Adds an interface to the cpm for the node but does not add any pollers.

=cut

sub NodeAddInterface {
  my ($self,$node_id,$data)=@_;

  $self->log_info("starting");
  my $request=$self->build_request('POST','Invoke/Orion.NPM.Interfaces/AddInterfacesOnNode',[$node_id,$data,'AddNoPollers']);
  my $result=$self->run_request($request);
  $self->log_info("stopping");

  return $result;
}

=item * my $result=$self->NodeInterfaceCustomProperties($nodeId,$interfaceId,$hash_ref|undef);

Used to get or set custom properties of an interfaec on a node.
Returns a Net::SolarWinds::Result Object: When true it contains the results, when false it contains the error.

=cut

sub NodeInterfaceCustomProperties {
  my ($self,$nodeId,$interfaceId,$data)=@_;

  my $request;
  $self->log_info("starting");
  if($data) {
    $request=$self->build_request('POST',"swis://localhost/Orion/Orion.Nodes/NodeID=$nodeId/Interfaces/InterfaceID=$interfaceId/CustomProperties",$data);
  } else {
    $request=$self->build_request('GET',"swis://localhost/Orion/Orion.Nodes/NodeID=$nodeId/Interfaces/InterfaceID=$interfaceId/CustomProperties");
  }
  my $result=$self->run_request($request);
  $self->log_info("stopping");
  return $result;
}

=item * my $query=$self->query_finder(@args);

Returns formatted SWQL query within a given function.  It finds the corrisponding constant via the $self->LOG_CLASS->lookback(2) call back.

=cut

sub query_lookup {
  my ($self,@args)=@_;

  # use the logging class look back to find our method.
  my $hash=$self->LOG_CLASS->lookback(2);

  my $method=$hash->{sub};
  $method=~ s/^.*::([^:]+)/$1/s;
  $self->log_debug("Starting look up of query: $method");
  my $query=$self->get_query($method);
  $self->log_debug("Finished look up of query: $method");

  $self->log_debug("Preparing query: $method Args: [",join(',',map { defined($_) ? qq{"$_"} : '""' } @args),']');
  my $swql=$self->prepare_query($query,@args);

  $self->log_debug("Preparing query: $method Looks like: $swql");

  return $swql;
}

=item * my $prepared=$self->prepare_query($query,@args);

Just a wrapper for: sprintf $query,@args

=cut

sub prepare_query {
  my ($self,$query,@args)=@_;

  return sprintf $query,@args;
}

=item * my $raw_query=$self->get_query($method);

Does an internal method lookup of SWQL_$method and returns the results of the method

=cut

sub get_query {
  my ($self,$method)=@_;

  my $constant="SWQL_$method";
  return 'QUERY NOT FOUND' unless $self->can($constant);

  return $self->$constant;
}

=item * my $result=$self->getInterfacesOnNode($NodeID);

Returns a Net::SolarWinds::Result Object

when true: Gets the interfaces from the node
when false: returns why it failed

=cut

sub getInterfacesOnNode {
  my ($self,$node_id)=@_;
  my $query=$self->query_lookup($node_id);

  $self->log_info("starting $node_id");
  my $result=$self->Query($query);

  return $result unless $result;

  my $list=$result->get_data->{results};
  my $ints={};

  foreach my $int (@{$list}) {
    my @list=$self->InterfaceCaptionTranslation($int->{Caption});
    foreach my $ifname (@list) {
      $ints->{$ifname}=$int;
    }
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($ints);
}

=item * my $result=$self->GetAlertSettings($nodeid);

Returns a Net::SolarWinds::Result Object

when true: Contains the list of Orion.ForecastCapacity, for the given node
when false: returns why it failed

=cut

sub GetAlertSettings {
  my ($self,$node_id)=@_;
  $self->log_info("starting $node_id");
  my $query=$self->query_lookup($node_id);
  my $result=$self->Query($query);
  $self->log_info("finished $node_id");
  return $result;
}

=item * my $result=$self->NodeCustomProperties($nodeId,$hash_ref|undef);

Used to get or set custom properties of a node.
Returns a Net::SolarWinds::Result Object: When true it contains the results, when false it contains the error.

=cut

sub NodeCustomProperties {
  my ($self,$nodeId,$data)=@_;


  my $request;
  if($data) {
    
    $self->log_info("starting node_id: $nodeId mode: POST");
    $request=$self->build_request('POST',"swis://localhost/Orion/Orion.Nodes/NodeID=$nodeId/CustomProperties",$data);
  } else {
    $self->log_info("starting node_id: $nodeId mode: GET");
    $request=$self->build_request('GET',"swis://localhost/Orion/Orion.Nodes/NodeID=$nodeId/CustomProperties");
  }
  my $result=$self->run_request($request);
  $self->log_info("stopping");
  
  return $result;
}

=item * my $result=$self->Query($sql);

=item * my $result=$self->Query({"query"=>"SELECT Uri FROM Orion.Pollers WHERE PollerID=@p ORDER BY PollerID WITH ROWS 1 TO 3 WITH TOTALROWS","parameters"=>{"p"=>9}});

Used to run an sql query against CPM.
Returns a Net::SolarWinds::Result Object: When true it contains the results, when false it contains the error.



=cut

sub Query {
  my ($self,$sql)=@_;
  $self->log_info("starting");
  my $result;
  if(ref($sql) and ref($sql) eq 'HASH') {
    $self->log_info("called in post mode");
    $self->log_debug(Dumper($sql));
    my $path='Query';
    my $request=$self->build_request('POST',$path,$sql);
    $result=$self->run_request($request);
  } else {
    $self->log_info("called in get mode");
    $self->log_debug("$sql");
    my $path='Query?query='.uri_encode($sql);
    my $request=$self->build_request('GET',$path);
    $result=$self->run_request($request);
    $self->log_info("stopping");
  }
  return $result;
}

=item * my $result=$self->BulkUpdate({uris=>["swis://dev-che-mjag-01./Orion/Orion.Nodes/NodeID=4/Volumes/VolumeID=1", "swis://dev-che-mjag-01./Orion/Orion.Nodes/NodeID=4/Volumes/VolumeID=2", "swis://dev-che-mjag-01./Orion/Orion.Nodes/NodeID=4/Volumes/VolumeID=3"],properties=>{"NextPoll"=>"7/1/2014 9:06:19 AM","NextRediscovery"=>"7/1/2014 2:59:09 PM"}}); 

Used to update uris in bulk, returns a Net::SolarWinds::Result object.

=cut

sub BulkUpdate {
  my ($self,$ref)=@_;
  $self->log_info("starting");
  my $request=$self->build_request('POST','BulkUpdate',$ref);
  my $result=$self->run_request($request);
  $self->log_info("stopping");

  return $result
}

=item * my $result=$self->BulkDelete({uris=>["swis://dev-che-mjag-01./Orion/Orion.Nodes/NodeID=4/Volumes/VolumeID=1", "swis://dev-che-mjag-01./Orion/Orion.Nodes/NodeID=4/Volumes/VolumeID=2", "swis://dev-che-mjag-01./Orion/Orion.Nodes/NodeID=4/Volumes/VolumeID=3"]}); 

Used to delete uris in bulk, returns a Net::SolarWinds::Result object.

=cut

sub BulkDelete {
  my ($self,$ref)=@_;
  $self->log_info("starting");
  my $request=$self->build_request('POST','BulkDelete',$ref);
  my $result=$self->run_request($request);
  $self->log_info("stopping");

  return $result
}

=item * my $result=$self->getNodesByIp($ip);

Find a list of nodes by a given ip.
Returns a Net::SolarWinds::Result Object: When true it contains an array ref of the results, when false it contains the error.

=cut

sub getNodesByIp {
  my ($self,$ip)=@_;
  $self->log_info("starting $ip");
  my $query=$self->query_lookup($ip);
  my $result=$self->Query($query);
  $self->log_info("stopping");
  return $result;
}

=item * my $result=$self->getNodesByDisplayName($hostname);

Find a list of nodes by a given hostname.
Returns a Net::SolarWinds::Result Object: When true it contains an array ref of the results, when false it contains the error.

=cut

sub getNodesByDisplayName {
  my ($self,$ip)=@_;
  $self->log_info("starting $ip");
  my $query=$self->query_lookup($ip,$ip);
  my $result=$self->Query($query);
  $self->log_info("stopping");
  return $result;
}

=item * my $result=$self->getNodesByID($nodeid);

Returns a Net::SolarWinds::Result object that contains a list of objects that matched that nodeid

=cut

sub getNodesByID {
  my ($self,$id)=@_;
  $self->log_info("starting");
  my $query=$self->query_lookup($id);
  my $result=$self->Query($query);

  $self->log_info("stopping");
  return $result;
}

=item * my $result=$self->createNode(key=>value);

Creates a node.
Returns a Carter::Result Object: Retuns a data structure on sucess returns why it faield on false.

Note, there are no presets when using this method!

=cut

sub nopresetsCreateNode {
  my ($self,%args)=@_;

  $self->log_info("starting");
  # Caption 

  my $path='Create/Orion.Nodes';
  my $request=$self->build_request('POST',$path,{%args});
  my $result=$self->run_request($request);

  unless($result) {
    $self->log_error("Failed to create node error was: $result");
    $self->log_info("stopping");
    return $result;
  }
  my $swis=$result->get_data;
  $swis=~ s/(?:^"|"$)//sg;
  my ($node_id)=$swis=~ /(\d+)$/s;

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true({Uri=>$swis,NodeID=>$node_id});
}


=item * my $result=$self->createNode(key=>value);

Creates a node.
Returns a Carter::Result Object: Retuns a data structure on sucess returns why it faield on false.

  # the defautl key/value list is
    qw(
      ObjectSubType      SNMP
      EntityType         Orion.Nodes
      DynamicIP          false
      EngineID           1
      Status             1
      UnManaged          false
      Allow64BitCounters true
      ObjectSubType      SNMP
      SNMPVersion        2
      Community          public
      VendorIcon         8072.gif
      NodeDescription    Hardware

    ),
      IOSImage=>"",
      IOSVersion=>"",
      Pollinterval=>60,
      SysObjectID=>"1.3.6.1.4.1.8072.3.2.10",
      MachineType=>"net-snmp - Linux",
      StatCollection=>10,
      CPULoad=>"-2",
      MemoryUsed=>"-2",
      PercentMemoryUsed=>"-2",
      BufferNoMemThisHour=>"0",
      BufferNoMemToday=>"0",
      BufferSmMissThisHour=>"0",
      BufferSmMissToday=>"0",
      BufferMdMissThisHour=>"0",
      BufferMdMissToday=>"0",
      BufferBgMissThisHour=>"0",
      BufferBgMissToday=>"0",
      BufferLgMissThisHour=>"0",
      BufferLgMissToday=>"0",
      BufferHgMissThisHour=>"0",
      BufferHgMissToday=>"0",
  

=cut

sub createNode {
  my ($self,%args)=@_;

  $self->log_info("starting");
  # Caption 
  %args=(
    qw(
      ObjectSubType      SNMP
      EntityType         Orion.Nodes
      DynamicIP          false
      EngineID           1
      Status             1
      UnManaged          false
      Allow64BitCounters true
      ObjectSubType      SNMP
      SNMPVersion        2
      Community          public
      VendorIcon         8072.gif
      NodeDescription    Hardware

    ),
      IOSImage=>"",
      IOSVersion=>"",
      Pollinterval=>60,
      SysObjectID=>"1.3.6.1.4.1.8072.3.2.10",
      MachineType=>"net-snmp - Linux",
      StatCollection=>10,
      CPULoad=>"-2",
      MemoryUsed=>"-2",
      PercentMemoryUsed=>"-2",
      BufferNoMemThisHour=>"0",
      BufferNoMemToday=>"0",
      BufferSmMissThisHour=>"0",
      BufferSmMissToday=>"0",
      BufferMdMissThisHour=>"0",
      BufferMdMissToday=>"0",
      BufferBgMissThisHour=>"0",
      BufferBgMissToday=>"0",
      BufferLgMissThisHour=>"0",
      BufferLgMissToday=>"0",
      BufferHgMissThisHour=>"0",
      BufferHgMissToday=>"0",
      %args
  );

  unless(exists $args{IPAddress}) {
    $self->log_error("IPAddress must be set");
    $self->log_info("stopping");
    return $self->RESULT_CLASS->new_false("IPAddress must be set");
  }

  # start building our required but often times missing key value pairs
  $args{IPAddressGUID}=$self->ip_to_gui($args{IPAddress}) unless exists $args{IPAddressGUID};
  $args{Caption}=$self->ip_to_reverse_hex($args{IPAddress}) unless exists $args{Caption};
  
  $self->log_info('stopping');

  return $self->nopresetsCreateNode(%args);
}

=item * my $result=$self->getNodeUri($node_id);

When true the Net::SolarWinds::Result object contains the node uri.
When false it contains why it failed.

=cut

sub getNodeUri {
  my ($self,$node_id)=@_;

  $self->log_info("starting");
  #my $query="Select Uri from Orion.Nodes where NodeId=$node_id";
  my $query=$self->query_lookup($node_id);

  my $result=$self->Query($query);

  unless($result) { 
    $self->log_error("could not get node uri error was: $result");
    $self->log_info("stopping");
    return $result;
  }

  unless($#{$result->get_data->{results}} >-1) {
    $self->log_error("NodeId: $node_id not found!");
    $self->log_info("stopping");
    return $self->RESULT_CLASS->new_false("NodeId: $node_id not found!") 
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($result->get_data->{results}->[0]->{Uri});

}

=item * my $result=$self->deleteSwis($uri);

Returns a charter result object showing status.

=cut

sub deleteSwis {
  my ($self,$uri)=@_;
  $self->log_info("starting");
  my $request=$self->build_request('DELETE',$uri);
  my $result=$self->run_request($request);
  $self->log_info("stopping");

  return $result;
}

=item * my $result=$self->deleteNode($node_id);

Deletes a given node.

=cut

sub deleteNode {
  my ($self,$node_id)=@_;
  my $path;

  $self->log_info("starting");
  if(my $result=$self->getNodeUri($node_id)) {
    $path=$result->get_data;
  } else {
    $self->log_error("Failed to delete node: $node_id error was: $result");
    $self->log_info("stopping");
    return $result;
  }
  my $request=$self->build_request('DELETE',$path);
  my $result=$self->run_request($request);
  $self->log_info("stopping");
  return $result;
}

=item * my $result=$self->getApplicationTemplate(@names);

This is a wrapper for the Query interface.  Returns the results that match applications by this name.

=cut

sub getApplicationTemplate {
  my ($self,@names)=@_;

  $self->log_info("starting");
  my $append=join ' OR ',map { sprintf q{Name='%s'},$_ } @names;
  my $query=$self->query_lookup($append);
 
  my $result=$self->Query($query);
  $self->log_info("stopping");
  return $result;
}

=item * my $result=$self->addTemplateToNode($node_id,$template_id);

=item * my $result=$self->addTemplateToNode($node_id,$template_id,$cred_id);

Adds a monitoring template with the default credentals to the node.
Returns true on success false on failure.

=cut

sub addTemplateToNode {
  my ($self,$node_id,$template_id,$cred_id)=@_;
  $cred_id=-4 unless defined($cred_id);
  $self->log_info("starting node_id: $node_id template_id: $template_id credential_id: $cred_id");
  my $request=$self->build_request(
    'POST',
    'Invoke/Orion.APM.Application/CreateApplication',
    [$node_id,$template_id,$cred_id,JSON::true]
  );
  my $result=$self->run_request($request);
  unless($result) {
    $self->log_error("Failed to addTemplateToNode error was: $result");
    $self->log_info("stopping");
    return $result;
  }

  if($result->get_data == -1) {
    my $msg="TemplateID: $template_id all ready exists on node";
    $self->log_error($msg);
    $self->log_info("stopping");
    return $self->RESULT_CLASS->new_false($msg);
  }

  $self->log_info("stopping");
  return $result;
}

=item * my $result=$self->getTemplatesOnNode($node_id);

Returns a Net::SolarWinds::Result object
When true it contains the templates on the node
when false it contains why it failed.

=cut

sub getTemplatesOnNode {
  my ($self,$node_id)=@_;
    $self->log_info("starting");
  my $query=$self->query_lookup($node_id);
  my $result=$self->Query($query);
  unless($result) {
    $self->log_error("failed to getTemplatesOnNode");
    $self->log_info("stopping");
    return $result;
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($result->get_data->{results});
}

=item * my $result=$self->UpdateNodeProps($nodeID,key=>values);

Has 2 use cases Read/Write: When called with just the $nodeID the result object is populated with the node properties.  When called with a hash the given values are pushed to the node.  Returns a Net::SolarWinds::Result object: true on success false on failure.

=cut

sub UpdateNodeProps {
  my ($self,$nodeID,%args)=@_;

  $self->log_info("starting node_id: $nodeID");
  my $uri='swis://localhost/Orion/Orion.Nodes/NodeID='.$nodeID;

  my $request; 
  if(scalar(keys(%args))==0) {
    $self->log_info("called in Read mode");
    $request=$self->build_request('GET',$uri);
  } else {
    $self->log_info("called in Write mode");
    $request=$self->build_request('POST',$uri,{%args});
  }
  my $result=$self->run_request($request);
  $self->log_info("stopping $nodeID");
  return $result;
}


=item * my $result=$self->AddPollerToNode($nodeID,$Poller);

Adds a poller to a node.

=cut


sub AddPollerToNode {
  my ($self,$node_id,$poller)=@_;

  $self->log_info("starting node_id: $node_id poller: $poller");
  my $result=$self->add_poller($node_id,'N',$poller);
  $self->log_info("stopping node_id: $node_id poller: $poller");
  return $result;
}

=item * my $result=$self->add_poller($node_id,$t,$poller)

Returns a Net::SolarWinds::Result object when true it returns the result information that shows the results of the poller being added.

=cut

sub add_poller {
  my ($self,$node_id,$t,$poller)=@_;

  $self->log_info("starting object_id: $node_id type: $t poller: $poller");

  my $json={
    PollerType=>$poller,
    NetObjectType=>$t,
    NetObject=>$t.':'.$node_id,
    NetObjectID=>$node_id,
  };

  my $request=$self->build_request('POST','Create/Orion.Pollers',$json);
  my $result=$self->run_request($request);
  unless($result) {
    $self->log_error("failed to add poller to node_id: $node_id type: $t poller: $poller error was: $result");
    $self->log_info("stopping");
    return $result;
  }
  my $url=$result->get_data;
  $url=~ s/(?:^"|"$)//g;

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($url);
}

=item * my $result=$self->add_volume(key=>value);

Creates a volume given the arguments passed in.

Returns a Net::SolarWinds::Result object:
When false it contains why it failed
When true it returns a swis uri

=cut

sub add_volume {
  my ($self,%args)=@_;

  $self->log_info("starting");
  my $json={
    VolumeIndex=>2,
    Caption=>"/",
    VolumeDescription=>"/",
    Status=>1,
    VolumeType=>"Fixed Disk",
    VolumeTypeIcon=>"FixedDisk.gif",
    VolumeSpaceAvailable=>0,
    VolumeSize=>0,
    VolumePercentUsed=>0,
    VolumeSpaceUsed=>0,
    VolumeTypeID=>4,
    PollInterval=>240,
    StatCollection=>15,
    RediscoveryInterval=>30,
   ,%args
  };

  my $request=$self->build_request('POST','Create/Orion.Volumes',$json);
  my $result=$self->run_request($request);

  $self->log_info("stopping");
  return $result;
}

=item * my $result=$self->getVolumeTypeMap;

Returns a Net::SolarWinds::Result Object
When true Returns the volume type map.
When false it returns why it failed.

=cut

sub getVolumeTypeMap {
  my ($self)=@_;

  $self->log_info("starting");
  my $query=$self->SWQL_getNodesByIp;
  my $result=$self->Query($query);
  unless($result) {
    $self->log_error("Failed to get getVolumeTypeMap error was: $result");
    $self->log_info("stopping");
    return $result;
  }

  my $list=$result->get_data->{results};

  my $map={};
  foreach my $type (@{$list}) {
    $map->{$type->{VolumeType}}=$type;
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($map);
}


=item * my $result=$self->getEngines;

Returns a Net::SolarWinds::Result object:
When true it contains the list of poller engins.
When false it contains why it failed.

=cut

sub getEngines {
  my ($self)=@_;

  my $result=$self->Query($self->SWQL_getEngines);

  return $result;
}

=item * my $result=$self->getEngine($engine);

Returns a Net::SolarWinds::Result Object:
When true it contains the list of matching engines.
When false it cointains why it failed.

Notes: if no matching engines were found the result object can be true.. but will not contain any data.

=cut

sub getEngine {
  my ($self,$engine)=@_;

  my $result=$self->Query($self->query_lookup($engine,$engine));

  return $result unless $result;
}

=item * my $result=$self->getVolumeMap($nodeID);

Returns a Net::SolarWinds::Result object:
When true it contains a hash that maps volumes to objects.
When false it returns why it failed.

=cut 

sub getVolumeMap {
  my ($self,$node_id)=@_;

  $self->log_info("starting");
  my $query=$self->query_lookup($node_id);
  my $result=$self->Query($query);
  unless($result) {
    $self->log_error("Failed to get getVolumeMap for node_id: $node_id error was: $result");
    $self->log_info("stopping");
    return $result;
  }

  my $list=$result->get_data->{results};
  my $map={};

  # set our max volume index to 1 if we don't have any volumes on this node
  my $MaxVolumeIndex=$#{$list} > -1 ? $list->[0]->{VolumeIndex} : 1;

  foreach my $vol (@{$list}) {
    # assume no duplicates.. 
    $map->{$vol->{Caption}}=$vol;
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true({'map'=>$map,MaxVolumeIndex=>$MaxVolumeIndex});

}

=item * my $result=$self->getSwisProps($uri);

Returns a Net::SolarWinds::Result object:
When true it the uri is set in the result hash
when false the explanation as to why it failed is gven.

=cut

sub getSwisProps {
  my ($self,$uri)=@_;
  $self->log_info("starting");
  my $request=$self->build_request('GET',$uri);
  my $result=$self->run_request($request);
  $self->log_info("stopping");
  return $result;
}

=item * my $result=$self->GetNodePollers($node_id,"N|V|I");

Returns a Net::SolarWinds::Result Object that contains the nodes when true when false it contains why it failed.

=cut

sub GetNodePollers {
  my ($self,$node_id,$type)=@_;
  $type='N' unless defined($type);
  $self->log_info("starting node_id: $node_id type: $type");
  my $query=$self->query_lookup($node_id,$type);
  my $result=$self->Query($query);

  unless($result) {
    $self->log_error("Failed to GetNodePollers on node_id: $node_id type: $type");
    $self->log_info("stopping");
    return $result;
  }

  my $list=$result->get_data->{results};
  my $pollers=[];
  foreach my $poller (@{$list}) {
    my $result=$self->getSwisProps('swis://localhost/Orion/Orion.Pollers/PollerID='.$poller->{PollerID});
    return unless $result;
    push @{$pollers},$result->get_data;
  }
  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($pollers);
}

=item * my $result=$self->UpdateUri($uri,%args);

Read/Write Interface used update or get the contents of $uri.  Returns a Net::SolarWinds::Result object.  Write Mode is used when %args contains values Read Mode is used when %args is empty

=cut

sub UpdateUri {
  my ($self,$uri,%args)=@_;

  $self->log_info("starting Uri: $uri");
  my $request; 
  if(scalar(keys(%args))==0) {
    $self->log_info("called in Read mode");
    $request=$self->build_request('GET',$uri);
  } else {
    $self->log_info("called in Write mode");
    $request=$self->build_request('POST',$uri,{%args});
  }
  my $result=$self->run_request($request);
  $self->log_info("stopping Uri $uri");
  return $result;
}

=back

=head1 SEE ALSO

Net::SolarWinds::REST::Batch

=head1 AUTHOR

Michael Shipper

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Mike Shipper

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
__END__
