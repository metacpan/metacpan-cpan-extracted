package Net::SolarWinds::REST::Batch;

=head1 NAME

Net::SolarWinds::REST::Batch - SolarWinds Batch Process class

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Data::Dumper;
  use Net::SolarWinds::REST::Batch

  my $self=new Net::SolarWinds::REST::Batch;

  my $result=$self->get_node('kstlldrmap04');

  die $result unless $result;

  print Dumper($result->get_data);



=head1 DESCRIPTION

A wrapper class for Net::SolarWinds::REST, that provides high level batch like interfaces that tie a lot of the smaller functions togeather.

=head1 Extends Net::SolarWinds::REST

All of the base funtions provided by Net::SolarWinds::REST are included in this module, for better or worse!

=cut


use strict;
use warnings;
use Data::Dumper;
use base qw(Net::SolarWinds::REST);

=head2 OO Methods

This section covers the OO Methods of the class.

=over 4

=item * my $result=$self->manage_node($struct,$allow_failure);


$allow_failure is optional, if not defined it is set to true.
The flag allows for the falure of anything other than the node itself not being created.

A fairly complex interface used to build out a node for management.

Example of the data of $struct:

  {
    # list of snmp pollers for the node
    # see also: add_pollers
    "node_pollers" => [
      "N.AssetInventory.Snmp.Generic",
      "N.Cpu.SNMP.HrProcessorLoad",
      "N.Details.SNMP.Generic",
      "N.Memory.SNMP.NetSnmpReal",
      "N.ResponseTime.ICMP.Native",
      "N.ResponseTime.SNMP.Native",
      "N.Status.ICMP.Native",
      "N.Status.SNMP.Native",
      "N.Topology_Layer3.SNMP.ipNetToMedia",
      "N.Uptime.SNMP.Generic"
    ],
   
    # see also: add_volumes
    "volumes" => ["/home/apm","/tmp","/var"],

    # The Network Interfaces to monitor
    # see also: manage_interfaces 
    "interfaces"=>["eth0","eth1","eth2"],

    "custom_properties"=>{
      "dcinstance" => "production",
      "administrator" => "EMS/NMS",
    },
   
    # denote if this node needs to be replaced as it is created
    # see also, build_node
    "replace" => false,

    # The disk volumes to monitor
    # Argumetns required to build a node
    # see also, build_node
    "node" => {
      "EngineID" => 18,
      "Status" => 1,
      "IPAddress" => "192.168.101.38",
      "RediscoveryInterval" => 30,
      "Community" => "public",
      "DisplayName" => "kstlldrmap04",
      "MachineType" => "net-snmp - Linux",
      "UnManaged" => false,
      "PollInterval" => 46,
      "StatCollection" => 10,
      "SysObjectID" => "1.3.6.1.4.1.8072.3.2.10",
      "SNMPVersion" => 2,
      "DynamicIP" => false,
      "Caption" => "kstlldrmap04",
      "ObjectSubType" => "SNMP",
      "VendorIcon" => "8072.gif            ",
      "Allow64BitCounters" => true
   },

   # Note: This requires the APM module in Solarwinds
   # denote objects used to create templates
   # see also: add_templates
   "templates" => [
      "SDS - Application details-U/L - Warning",
      "SDS - DMS Adaptor Daemon Monitor - Critical",
      "SDS - Drum - Warning",
      "AWS Mail Alert Daemon",
      "CPM Ghosting"
   ]
  }

=cut

sub manage_node {
  my ($self,$info,$allow_failure)=@_;
  $allow_failure=1 unless defined($allow_failure);
  
  $self->log_info("starting with $info->{node}->{IPAddress} replace: $info->{replace}");

  my $data={};

  my $result=$self->build_node($info->{node}->{IPAddress},$info->{replace},%{$info->{node}});
  unless($result) {
     my $msg="build_node $info->{node}->{IPAddress},$info->{replace} failed error was: $result";
     $self->log_error($msg);
     $self->log_info("stopping");
     return $self->RESULT_CLASS->new_false($msg);
  }
  $data->{node}=$result->get_data;
  my $node_id=$result->get_data->{NodeID};


  if(exists $info->{interfaces}) {
    $result=$self->manage_interfaces($node_id,@{$info->{interfaces}});
    unless($result) {
      my $msg="Failed durring interfaces update error was: ".$result;
      $self->log_error($msg);
      $self->log_info("stopping");
      return $self->RESULT_CLASS->new_false($msg) unless $allow_failure;
    }
    $data->{interfaces}=$result->get_data;
  }


  if(exists $info->{custom_properties}) {
    $result=$self->NodeCustomProperties($node_id,$info->{custom_properties});
    unless($result) {
      my $msg="Failed durring custom properties update error was: ".$result;
      $self->log_error($msg);
      $self->log_info("stopping");
      return $self->RESULT_CLASS->new_false($msg) unless $allow_failure;
    }
    $data->{custom_properties}=$result->get_data;
  }

  if(exists $info->{node_pollers}) {
    $result=$self->add_pollers($node_id,'N',@{$info->{node_pollers}});
    unless($result) {
      my $msg="Failed durring node pollers update error was: ".$result;
      $self->log_error($msg);
      $self->log_info("stopping");
      return $self->RESULT_CLASS->new_false($msg) unless $allow_failure;
    }
    $data->{node_pollers}=$result->get_data;
  }

  if(exists $info->{volumes}) {
    $result=$self->add_volumes($node_id,@{$info->{volumes}});
    unless($result) {
      my $msg="Failed durring volumes update error was: ".$result;
      $self->log_error($msg);
      $self->log_info("stopping");
      return $self->RESULT_CLASS->new_false($msg) unless $allow_failure;
    }
    $data->{volumes}=$result->get_data;
  }

  if(exists $info->{templates}) {
    $result=$self->add_templates($node_id,@{$info->{templates}});
    unless($result) {
      my $msg="Failed durring templates update error was: ".$result;
      $self->log_error($msg);
      $self->log_info("stopping");
      return $self->RESULT_CLASS->new_false($msg) unless $allow_failure;
    }
    $data->{templates}=$result->get_data;
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($data);
}

=item * my $result=$self->get_node($thing);

$thing can contain any one of the following: NodeID, IpAddress, Caption.

This method returns a Net::SolarWinds::Result object.

When true it contains the first node found that matched what was passed in as $thing.

When false it contains why it failed.

=cut

sub get_node {
  my ($self,$id)=@_;

  $self->log_info("starting id: $id");
  my $result;
  my $lookup;
  if($id=~ /^\d+$/) {
    $result=$self->getNodesByID($id);
    $lookup="id";
  } elsif($id=~ /\d\.\d/) {
    $result=$self->getNodesByIp($id);
    $lookup="ip";
  } else {
    $result=$self->getNodesByDisplayName($id);
    $lookup="hostname";
  } 

  unless($result) {
    $self->log_error($result);
    $self->log_info("stopping");
    return $result ;
  }
  my $list=$result->get_data->{results};

  if($#{$list}==-1) {
    my $msg="Node $id not found by $lookup";
    $self->log_debug(Dumper($result));
    $self->log_error($msg);
    $self->log_info("stopping");
    return $self->RESULT_CLASS->new_false($msg);
  }
  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($list->[0]);
}

=item * my $result=$self->set_managed($thing,0|1);

This is really just a wrapper for $self->get_node followed by $self->UpdateNodeProps($node_id,UnManaged=>0|1);

Returns a Net::SolarWinds::Result object

=cut

sub set_managed {
  my ($self,$ip,$state)=@_;
  $state=0 unless defined($state);

  my $result=$self->get_node($ip);
  return $result unless $result;
  my $node=$result->get_data;
  my $node_id=$node->{NodeID};

  return $self->UpdateNodeProps($node_id,UnManaged=>JSON::true);
}

=item * my $result=$self->get_management_config($thing);

Programatic way build a refrence template for: manage_node

Returns a Net::SolarWinds::Result object
If true, it contains a data structure requried to build out the node refred to as $thing.
If false, it contains why it failed.

=cut

sub get_management_config {
  my ($self,$ip)=@_;

  my $result=$self->get_node($ip);
  return $result unless $result;

  my $node=$result->get_data;
  my $node_id=$node->{NodeID};
  delete $node->{NodeID};
  delete $node->{Uri};
  delete $node->{EntityType};
  delete $node->{IPAddressGUID};

  $result=$self->get_poller_map($node_id,'N');
  return $result unless $result;
  my $node_pollers=[
    sort
    keys %{ $result->get_data->{"N:$node_id"} }
  ];

  $result=$self->getInterfacesOnNode($node_id);
  return $result unless $result;
  my $interfaces=[
    sort
    map { 
      my $int_id=$result->get_data->{$_}->{InterfaceID};
      my $res=$self->NodeInterfaceCustomProperties($node_id,$int_id);
      my $custom_props=$res ? $res->get_data : {};

      # clean up any properties that are not set
      delete $custom_props->{InterfaceID};
      delete $custom_props->{InstanceType};
      while (my ($key,$value)=each %{$custom_props}) {
        delete $custom_props->{$key} unless defined($value);
      }

      $res=$self->get_poller_map($int_id,'I');
      my $pollers=$res ? [ sort keys %{$res->get_data->{"I:$int_id"}}] : [];
      {
        ifname=>$_,
	custom_props=>$custom_props,
	pollers=>$pollers,
      }
    } 
    keys %{ $result->get_data }
  ];

  $result=$self->getVolumeMap($node_id);
  return $result unless $result;
  my $volumes=[
    map { 
      my $vol_id=$_->{VolumeID};
      my $res=$self->get_poller_map($vol_id,'V');
      my $pollers=$res ? [ sort keys %{$res->get_data->{"V:$vol_id"}}] : [];
      {
        path=>$_->{Caption},
	type=>$_->{Type},
	pollers=>$pollers,
      }
    } values %{ $result->get_data->{'map'} }
  ];

  $result=$self->NodeCustomProperties($node_id);
  return $result unless $result;

  my $custom_props=$result->get_data;
  delete $custom_props->{NodeID};
  delete $custom_props->{InstanceType};
  while(my ($key,$value)=each %{$custom_props}) {
    delete $custom_props->{$key} unless defined($value);
  }

  $result=$self->getTemplatesOnNode($node_id);
  return $result unless $result;

  my $templates=[];
  foreach my $tmpl (@{$result->get_data}) {
    push @{$templates},$tmpl->{Name};
  }
  my $config={
    node=>$node,
    node_pollers=>$node_pollers,
    interfaces=>$interfaces,
    volumes=>$volumes,
    custom_properties=>$custom_props,
    templates=>$templates,
  };

  $config->{replace}=&JSON::false;
  return $self->RESULT_CLASS->new_true($config);
}

=item * my $result=$self->get_poller_map($id,$type);

Used to get a uniqe hash of all pollers assigned to this object. 

$id can be: 
   NodeID $type=N
   VolumeID $type=V
   InterfaceID $type=I

Returns a Net::SolarWinds::Result object.

=cut

sub get_poller_map {
  my ($self,$node_id,$type)=@_;

  $type='N' unless defined($type);
  $self->log_info("starting node_id: $node_id type: $type");
  my $query=$self->query_lookup($node_id,$type);
  my $result=$self->Query($query);
  unless($result) {
    $self->log_error("query failed error was: $result");
    $self->log_info("stopping");
    return $result;
  }

  my $map={};

  my $list=$result->get_data->{results};

  foreach my $poller (@{$list}) {
    my $id=$poller->{NetObjectID};
    next if defined $type and $type ne $poller->{NetObjectType};
    $map->{$poller->{NetObject}}->{$poller->{PollerType}}=$poller;
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($map);
}

=item * my $result=$self->getPollerInterfaceMap($nodeid) 

Returns a Net::SolarWinds::Result object, when true it contains a hash mapping ifType to PollerType

=cut

sub getPollerInterfaceMap {
  my ($self,$nodeid)=@_;

  $self->log_info("Starting poller type lookup of nodeid: $nodeid");
  my $query=$self->query_lookup($nodeid);

  my $result=$self->Query($query);
  unless($result) {
    $self->log_error("Finished poller type lookup of nodeid: $nodeid error was: $result");
    return $result;
  }

  my $hash={};
  my $list=$result->get_data->{results};

  foreach my $poller (@{$list}) {
    my $id=$poller->{ifType};
    $hash->{$id}=[] unless exists $hash->{$id};
    push @{$hash->{$id}},$poller->{PollerType};
  }

  $self->log_info("Finished poller type lookup of nodeid: $nodeid");
  return $self->RESULT_CLASS->new_true($hash);
}

=item * my $result=$self->GetNodeInterfacePollers($nodeid) 

When true it returns a Net::SolarWinds::Result object that contains the interface poller and id info.

=cut

sub GetNodeInterfacePollers {
  my ($self,$nodeid)=@_;
  my $query=$self->query_lookup($nodeid);
  my $result=$self->Query($query);
  return $result;
}

=item * my $result=$self->add_pollers($id,$t,@pollers);

Adds a list of pollers of type to given id.

$id can be: 
   NodeID $type=N
   VolumeID $type=V
   InterfaceID $type=I

@polers contains a list of snmp pollers.  

Example:

  "N.Details.SNMP.Generic",
  "N.ResponseTime.ICMP.Native",
  "N.ResponseTime.SNMP.Native",
  "N.Status.ICMP.Native",
  "N.Status.SNMP.Native",
  "N.Uptime.SNMP.Generic"

Returns a Net::SolarWinds::Result Object.

=cut

sub add_pollers {
  my ($self,$node_id,$t,@pollers)=@_;

  $self->log_info("Starting object_id: $node_id type: $t pollers: ".join ', ',@pollers);

  my $result=$self->get_poller_map($node_id,$t);
  unless($result) {
    $self->log_error("failed to get_poller_map error was: $result");
    $self->log_info("stopping");
    return $result;
  }
  my $id=$t.':'.$node_id;

  my $map=$result->get_data;

  my $pollers=[];
  foreach my $poller (@pollers) {
    # skip duplicate pollers
    if(exists $map->{$id}->{$poller}) {
      $self->log_warn("poller $poller exists on object $node_id skipping!");
      next 
    }
    my $result=$self->add_poller($node_id,$t,$poller);
    unless($result) {
      $self->log_error("Faield to add poller for object_id $node_id type: $t poller: $poller error was $result");
      $self->log_info("stopping");
      return $result;
    }
    push @{$pollers},$result->get_data;
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($pollers);
}

=item * my $result=$self->add_volumes($node_id,@vols);

$node_id is the NodeID of the device

@vols can contain a mix of [either list of objects or volume names.

Object Example:

 {
   "pollers" => [
     "V.Details.SNMP.Generic",
     "V.Statistics.SNMP.Generic",
     "V.Status.SNMP.Generic"
   ],
   "type" => "Network Disk",
   "path" => "/home/apm"
 },

String Example:

  '/var'

When using the string example, the default pollers are added.

=cut

sub add_volumes {
  my ($self,$node_id,@vols)=@_;

  $self->log_info("starting node_id: $node_id");
  my $result=$self->getVolumeTypeMap;
  unless($result) {
    $self->log_error("Failed to get getVolumeTypeMap error was: $result");
    $self->log_info("stopping");
    return $result;
  }

  my $map=$result->get_data;

  $result=$self->getVolumeMap($node_id);
  unless($result) {
    $self->log_error("Failed to get getVolumeMap error was: $result");
    $self->log_info("stopping");
    return $result;
  }

  my $vol_map=$result->get_data->{'map'};
  my $MaxVolumeIndex=$result->get_data->{MaxVolumeIndex};

  my $added={};
  PROV_LOOP: foreach my $vol (@vols) {
    # force the object to a hash ref..
    $vol={path=>$vol} 
      unless ref($vol) and ref($vol) eq 'HASH';
    my $path=$vol->{path};
    my $obj;
    if(exists $vol_map->{$path}) {
      $self->log_warn("volume in monitoring all ready, will not re-add: $path");
      $obj=$vol_map->{$path};
    } else {
      ++$MaxVolumeIndex;
      $self->log_warn("volume does not exist we will create: $path");
      #%{ $map->{$vol->{type}}},

      my %args=(
        Caption=>$path,
        VolumeDescription=>$path,
        NodeID=>$node_id,
	VolumeIndex=>$MaxVolumeIndex,
      );

      $self->log_always("Adding volume with options: ",Dumper(\%args));
      $result=$self->add_volume(%args);
      unless($result) {
        $self->log_warn("failed to add volume $path error was: $result");
        next PROV_LOOP;
      }

      my $url=$result->get_data;
      $url=~ s/(?:^"|"$)//g;
      my ($VolumeID)=$url=~ /(\d+)$/;
      $args{VolumeID}=$VolumeID;
      $obj={%args};
      $added->{$path}->{obj}=$obj;
    }

    if(exists $vol->{pollers} and  ref($vol->{pollers}) eq 'ARRAY') {
      my $pollers=$vol->{pollers};
      my $volume_id=$obj->{VolumeID};
        my $result=$self->add_pollers($volume_id,'V',@{$pollers});
	if($result) {
	  $added->{$path}->{pollers}=$result->get_data;
        } else {
	  $self->log_error("failed to add pollers to volume: $volume_id error was: $result");
	  $self->log_info("stopping");
	  $added->{$path}->{pollers}={ERROR=>"$result"};
	}
    }
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($added);
}

=item * my $result=$self->add_templates($node_id,@templates);

Add a list of templates to the device for monitoring.

$$node_id is the NodeID of the node

@templates Example list:

      "SDS - Application details-U/L - Warning",
      "SDS - DMS Adaptor Daemon Monitor - Critical",
      "SDS - Drum - Warning",
      "AWS Mail Alert Daemon",
      "CPM Ghosting"

=cut

sub add_templates {
  my ($self,$node_id,@templates)=@_;

  my $list=[];
  if(@templates) {
    my $result=$self->getApplicationTemplate(@templates);
    return $result unless $result;
    $list=$result->get_data->{results};
  }

  my $tmpls=[];
  foreach my $tmpl (@{$list}) {
    my $id=$tmpl->{ApplicationTemplateID};
    my $result=$self->addTemplateToNode($node_id,$id);
    next unless $result;
    push @{$tmpls},$result->get_data;
  }

  return $self->RESULT_CLASS->new_true($tmpls);
}

=item * my $result=$self->manage_interfaces($node_id,@interfaces);

$node_id is the "NodeID" of the machine to work with

@interfaces contains a list of Object hashes or interface names.

Object Example: In the object example all details, such as the pooler and custom properties are set manually.

 {
   "pollers" : [
     "I.Rediscovery.SNMP.IfTable",
     "I.StatisticsErrors32.SNMP.IfTable",
     "I.StatisticsTraffic.SNMP.Universal",
     "I.Status.SNMP.IfTable"
   ],
   "ifname" : "eth1",
     "custom_props" : {
     "alert_rx_percent_utilization" : 90,
     "alarmerrorrate" : 0,
     "alert_tx_percent_utilization" : 90
   }
 }

Interface name example:  In the interface name example just the name of the interface is passed.

  'eth0'


Odds are you will just want to use a list of human readable interface names:

  "eth0","eth1","eth2"

Notes:

Gives up at the first error, and may not complete the process of adding things.  Odds are this code will need to be made more forgiving.

=cut

sub manage_interfaces {
  my ($self,$node_id,@interfaces)=@_;
  $self->log_info("starting node_id: $node_id");

  my $result=$self->DiscoverInterfaceMap($node_id);
  unless($result) {
    $self->log_error("failed to discover interfaces on node_id: $node_id error was: $result");
    $self->log_info("stopping");
    return $result;
  }

  my $map=$result->get_data;
  $self->log_debug("Interfaces: ".Dumper($map));
  
  my $add_poller=[];
  my $no_add_poller=[];
  my $add_pollers=[];
  my $add_pollers_to={};
  my $set_props={};

  foreach my $obj (@interfaces) {
    my ($int,$ref);

    if(ref($obj) eq 'HASH') {
      $int=$obj->{ifname};
      unless(exists $map->{$int}) {
        $self->log_warn("ifname $int was not found in the discovery table!");
        next;
      }
      $ref=$map->{$int};
      $set_props->{$int}=$obj 
        if exists $obj->{custom_props} 
	  and ref($obj->{custom_props}) eq 'HASH' 
	  and keys(%{$obj->{custom_props}})!=0;
      if(exists $obj->{pollers} and ref($obj->{pollers}) eq 'ARRAY') {
        
        if($#{$obj->{pollers}}!=-1) {
	  # use explicit pollers
          push @{$add_pollers},$int;
	  $add_pollers_to->{$int}=$obj;
	  if($ref->{InterfaceID}!=0) {
	    $self->log_warn("ifname $int is all ready managed");
            next;
	  }
          $self->log_info("ifname $int exists does not yet have an id we will addd it with custom properties!");
          push @{$no_add_poller},$ref;
	} else {
	  # only set default polelrs if the list is empty
	  if($ref->{InterfaceID}!=0) {
	    $self->log_warn("ifname $int is all ready managed");
            next;
	  }
          $self->log_info("ifname $int exists does not yet have an id we will addd it to default pollers");
          push @{$add_poller},$ref;
	}
      } elsif($ref->{InterfaceID}!=0) {
         push @{$add_poller},$ref;
      }
      
    } else {
      $int=$obj;
      unless(exists $map->{$int}) {
        $self->log_warn("ifname $int was not found in the discovery table!");
        next;
      }
      $ref=$map->{$int};
      next if $ref->{InterfaceID}!=0;
      $self->log_info("ifname $int exists does not yet have an id we will addd it to default pollers");
      push @{$add_poller},$ref;
    }
  }
  my $data=[];
  if($#{$add_poller} > -1) {
    $result=$self->NodeInterfaceAddDefaultPollers($node_id,$add_poller);
    return $result unless $result;
    foreach my $obj (@{$result->get_data->{DiscoveredInterfaces}}) {
      foreach my $int ($self->InterfaceCaptionTranslation($obj->{Caption})) {
	push @{$data},$int;
      }
    }
  }
  
  if($#{$no_add_poller} > -1) {
    $result=$self->NodeAddInterface($node_id,$no_add_poller);
    return $result unless $result;
    my $tmap=$self->build_interface_result_map($result)->get_data;
    %{$map}=(
      %{$map},
      %{$tmap}
    );
    foreach my $int (@{$add_pollers}) {
      next unless exists $map->{$int};
      my $obj=$add_pollers_to->{$int};
      my $id=$map->{$int}->{InterfaceID};
      my $result=$self->add_pollers($id,'I',@{$obj->{pollers}});
      return $result unless $result;
      push @{$data},$obj;
    }
  }

  while (my ($int,$ref)=each %{$set_props}) {
    next unless exists $map->{$int};
    my $result=$self->NodeInterfaceCustomProperties($node_id,$map->{$int}->{InterfaceID},$ref->{custom_props});
    return $result unless $result;
  }
  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true($data);
}

=item * my $result=$self->create_or_update_node($ip,%args);

Wrapper for $self->build_node with $DeleteIfExists set to false

=cut

sub create_or_update_node {
  my ($self,$ip,%args)=@_;
  return $self->build_node($ip,0,%args);
}

=item * my $result=$self->replace_node($ip,%args);

Wrapper for $self->build_node with $DeleteIfExists set to true

=cut

sub replace_node {
  my ($self,$ip,%args)=@_;
  return $self->build_node($ip,1,%args);
}

=item * my $result=$self->build_node($ip,$DeleteIfExists,%args);

Used to create a node if it does not exist.

Variabels:
  $ip
    The ipv4 address of the box

  $DeleteIfExists 
    if this value is set to true and this node exists all ready
    it will be deleted and re-created!

  %args
    The node properties
    See also: Net::SolarWinds::REST::UpdateNodeProps

=cut

sub build_node {
  my ($self,$ip,$DeleteIfExists,%args)=@_;

  $self->log_info("Starting lookup of $ip");
  my $nodeID;
  my $result=$self->get_node($ip);
  $args{IPAddress}=$ip unless exists $args{IPAddress};
  
  
  if($result) {
      $nodeID=$result->get_data->{NodeID};
      $self->log_info("Node exists: NodeID is $nodeID");
      if($DeleteIfExists) {
	$self->log_info("Node exists we were called in replace mode");
        my $result=$self->deleteNode($nodeID);
	unless($result) {
	  $self->log_error("Failed to delete NodeID: $nodeID");
          $self->log_info("stopping");
          return $result;
	}
	$nodeID=undef;
      } else {
	$self->log_info("Node exists and we were called in update mode");
	$result=$self->UpdateNodeProps($nodeID);
	unless($result) {
	  $self->log_error("Failed to fetch node propeties  for NodeID: $nodeID");
          $self->log_info("stopping");
          return $result;
	}
	my $existing=$result->get_data;
	my $update=0;
	UPDATE_CHECK: while(my ($key,$value)=each %args) {
	  # work around, we don't want to update node status!
	  next UPDATE_CHECK if $key eq 'Status';

          # work around, we don't want to do an eq against numbers
	  my $cmp="$value";
	  if(exists $existing->{$key} and defined($existing->{$key})) {
            # work around, we don't want to do an eq against numbers
	    my $current=''.$existing->{$key};

	    # work around cpm returns some space padded values
	    $current=~ s/(?:^\s+|\s+$)//g;
	    $cmp=~ s/(?:^\s+|\s+$)//g;

	    if($cmp ne $current) { 
	      $update=1;
	      $self->log_warn("Values do not match [$cmp] ne [$value] on node will need to update");
	      last UPDATE_CHECK;
	    }
	  } else {
	    $update=1;
	    $self->log_warn("Value on node s incorrect will need to update");
	    last UPDATE_CHECK;
	  }
	}

        if($update) {
          $result=$self->UpdateNodeProps($nodeID,%args);
	  unless($result) {
	    $self->log_error("Failed to update NodeID: $nodeID");
            $self->log_info("stopping");
            return $result;
 	}
      }
    }
  }

  unless($nodeID) {
    $self->log_info("Creating node $ip");
    my $result=$self->createNode(%args);
    $self->log_error("Failed to create node: $ip error was: $result") unless($result);
    $self->log_info("stopping");
    return $result;
  }

  $self->log_info("stopping");
  return $self->RESULT_CLASS->new_true({NodeID=>$nodeID});

}

=item * my $result=$self->build_unmanaged($ip,$DeleteIfExists,%args);

Wrapper for build_node, flips the node to UnManaged=>1 once it has been created or if it all ready exists.

=cut

sub build_unmanaged {
  my ($self,$ip,$DeleteIfExists,%args)=@_;

  $self->log_info("Starting build_unmanaged");
  my $result=$self->build_node($ip,$DeleteIfExists,%args);
  return $result unless $result;

  my $nodeID=$result->get_data->{NodeID};
  my $target=$result;

  $result=$self->NodeUnmanage($nodeID);

  $self->log_info("Finished build_unmanaged");
  return $result unless $result;

  return $target;
}

=back

=head1 AUTHOR

Michael Shipper

=cut

1;

__END__
