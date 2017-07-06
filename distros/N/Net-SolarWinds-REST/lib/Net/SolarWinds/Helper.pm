package Net::SolarWinds::Helper;

use strict;
use warnings;

=head1 NAME

Net::SolarWinds::Helper - Common OO Methods

=head1 SYNOPSIS

  use base qw(Net::SolarWinds::Helper);

=head1 DESCRIPTION

This class provides common OO methods used to for Solarwinds development.  These methods are all stand alone.

=over 4

=item * my $reverse_hex=$self->ip_to_reverse_hex($ip);

Converts an IP into hex with the octets swapped to reverse order.

=cut 

sub ip_to_reverse_hex {

  my ($self,$ip)=@_;

  my $hex=unpack("H8",reverse(pack("C4",split(/\./,$ip))));

  return $hex;
}

=item * my $gui_ip=$self->ip_to_gui($ip);

Converts a quad notation ip to the gui display version SolarWinds uses..

=cut

sub ip_to_gui {
  my ($self,$ip)=@_;

  my $hex=$self->ip_to_reverse_hex($ip);

  $hex .="-0000-0000-0000-000000000000";

  return $hex;
}

=item * my $swis=$self->nodeUri($node_id);

Returns the node Uri based on the $node_id

=cut

sub nodeUri {
  my ($self,$nodeId)=@_;
  return "swis://localhost/Orion/Orion.Nodes/NodeID=$nodeId";
}

=back

=head1 Query Drivers

Many of the internals use site spesific SWQL statements, they are defined as constants in this class. Since some of these queries are Solarwinds install spesific it may be required to overload some of these queries.

=head2 Query Drivers For: Net::SolarWinds::REST

=over 4

=item * my $sql=$self->SWQL_getInterfacesOnNode;

=cut

use constant SWQL_getInterfacesOnNode=>'SELECT Caption, InterfaceID, DisplayName, FullName, ifname, interfacetype as ifType,Uri FROM Orion.NPM.Interfaces where NodeID=%s';

=item * my $sql=$self->SWQL_getNodesByDisplayName;

=cut

use constant SWQL_getNodesByDisplayName=>q{SELECT
  NodeID,
  IPAddress,
  IPAddressGUID,
  Caption,
  DynamicIP,
  EngineID,
  Status,
  UnManaged,
  Allow64BitCounters,
  ObjectSubType,
  SysObjectID,
  MachineType,
  VendorIcon,
  SNMPVersion,
  Community,
  RediscoveryInterval,
  PollInterval,
  StatCollection,
  Uri,
  DisplayName
  FROM Orion.Nodes where DisplayName='%s' OR Caption='%s'};

=item * my $sql=$self->SWQL_getNodesByID;

=cut

use constant SWQL_getNodesByID=>q{SELECT
  NodeID,
  IPAddress,
  IPAddressGUID,
  Caption,
  DynamicIP,
  EngineID,
  Status,
  UnManaged,
  Allow64BitCounters,
  ObjectSubType,
  SysObjectID,
  MachineType,
  VendorIcon,
  SNMPVersion,
  Community,
  RediscoveryInterval,
  PollInterval,
  StatCollection,
  Uri
  FROM Orion.Nodes where NodeId='%s'};

=item * my $sql=$self->SWQL_getApplicationTemplate;

=cut

use constant SWQL_getApplicationTemplate=>q{SELECT ApplicationTemplateID, Created, CustomApplicationType, Description, DisplayName, HasImportedView, InstanceType, IsMockTemplate, LastModified, Name, Uri, ViewID, ViewXml FROM Orion.APM.ApplicationTemplate where %s};

=item * my $sql=$self->SWQL_getTemplatesOnNode;

=cut

use constant SWQL_getTemplatesOnNode=>q{SELECT ApplicationID, ApplicationTemplateID, Description, DetailsUrl, DisplayName, HasCredentials, ID, InstanceType, Name, NodeID, Uri FROM Orion.APM.Application where nodeid=%s};

=item * my $sql=$self->SWQL_getNodesByIp;

=cut

use constant SWQL_getNodesByIp=>q{SELECT
  n.NodeID,
  n.IPAddress,
  n.IPAddressGUID,
  n.Caption,
  n.DynamicIP,
  n.EngineID,
  n.Status,
  n.UnManaged,
  n.Allow64BitCounters,
  n.ObjectSubType,
  n.SysObjectID,
  n.MachineType,
  n.VendorIcon,
  n.SNMPVersion,
  n.Community,
  n.RediscoveryInterval,
  n.PollInterval,
  n.StatCollection,
  n.Uri,
  n.DisplayName
  FROM 
    Orion.NodeIPAddresses i
    inner join Orion.Nodes n on n.ObjectSubType='SNMP' and i.NodeID=n.NodeID
  where  
    i.IPAddress='%s'};

=item * my $sql=$self->SWQL_bulk_ip_lookup

=cut

use constant SWQL_bulk_ip_lookup=>q{SELECT
  n.NodeID,
  n.IPAddress,
  n.IPAddressGUID,
  n.Caption,
  n.DynamicIP,
  n.EngineID,
  n.Status,
  n.UnManaged,
  n.Allow64BitCounters,
  n.ObjectSubType,
  n.SysObjectID,
  n.MachineType,
  n.VendorIcon,
  n.SNMPVersion,
  n.Community,
  n.RediscoveryInterval,
  n.PollInterval,
  n.StatCollection,
  n.Uri,
  n.DisplayName,
  i.IPAddress as LookupIP
  FROM 
    Orion.NodeIPAddresses i
    inner join Orion.Nodes n on n.ObjectSubType='SNMP' and i.NodeID=n.NodeID
  where  
    i.IPAddress in('%s')};

=item * my $sql=$self->SWQL_getVolumeTypeMap;

=cut

use constant SWQL_getVolumeTypeMap=>q{SELECT distinct VolumeType, VolumeTypeIcon, VolumeTypeID FROM Orion.Volumes};

=item * my $sql=$self->SWQL_getEngines;

=cut

use constant SWQL_getEngines=>q{SELECT AvgCPUUtil, BusinessLayerPort, CompanyName, CustomerID, Description, DisplayName, Elements, EngineID, EngineVersion, EvalDaysLeft, Evaluation, FailOverActive, FIPSModeEnabled, InstanceType, InterfacePollInterval, Interfaces, InterfaceStatPollInterval, IP, KeepAlive, LicensedElements, LicenseKey, MaxPollsPerSecond, MaxStatPollsPerSecond, MemoryUtil, MinutesSinceFailOverActive, MinutesSinceKeepAlive, MinutesSinceRestart, MinutesSinceStartTime, MinutesSinceSysLogKeepAlive, MinutesSinceTrapsKeepAlive, NodePollInterval, Nodes, NodeStatPollInterval, PackageName, Pollers, PollingCompletion, PrimaryServers, Restart, SerialNumber, ServerName, ServerType, ServicePack, StartTime, StatPollInterval, SysLogKeepAlive, TrapsKeepAlive, Uri, VolumePollInterval, Volumes, VolumeStatPollInterval, WindowsVersion FROM Orion.Engines};

=item * my $sql=$self->SWQL_getNodeUri;

=cut

use constant SWQL_getNodeUri=>'Select Uri from Orion.Nodes where NodeId=%s';

=item * my $sql=$self->SWQL_getEngine;

=cut

use constant SWQL_getEngine=>q{SELECT AvgCPUUtil, BusinessLayerPort, CompanyName, CustomerID, Description, DisplayName, Elements, EngineID, EngineVersion, EvalDaysLeft, Evaluation, FailOverActive, FIPSModeEnabled, InstanceType, InterfacePollInterval, Interfaces, InterfaceStatPollInterval, IP, KeepAlive, LicensedElements, LicenseKey, MaxPollsPerSecond, MaxStatPollsPerSecond, MemoryUtil, MinutesSinceFailOverActive, MinutesSinceKeepAlive, MinutesSinceRestart, MinutesSinceStartTime, MinutesSinceSysLogKeepAlive, MinutesSinceTrapsKeepAlive, NodePollInterval, Nodes, NodeStatPollInterval, PackageName, Pollers, PollingCompletion, PrimaryServers, Restart, SerialNumber, ServerName, ServerType, ServicePack, StartTime, StatPollInterval, SysLogKeepAlive, TrapsKeepAlive, Uri, VolumePollInterval, Volumes, VolumeStatPollInterval, WindowsVersion FROM Orion.Engines where ServerName='%s' or DisplayName='%s'};

=item * my $sql=$self->SWQL_getVolumeMap;

=cut

use constant SWQL_getVolumeMap=>q{SELECT
    VolumeIndex,
    Caption,
    VolumeDescription,
    Status,
    Type ,
    Icon ,
    VolumeSpaceAvailable,
    VolumeSize,
    VolumePercentUsed,
    VolumeSpaceUsed,
    VolumeTypeID,
    PollInterval,
    StatCollection,
    RediscoveryInterval,
    VolumeID,
    Uri,
    NodeID

  FROM Orion.Volumes where NodeID=%s};

=item * my $sql=$self->SWQL_GetAlertSettings;

=cut

use constant SWQL_GetAlertSettings=>'SELECT NodeID, EntityType, InstanceId, MetricId, MetricName, InstanceCaption, ThresholdType, Timestamp, MinDateTime, MaxDateTime, CurrentValue, WarningThreshold, CriticalThreshold, CapacityThreshold, Aavg, Bavg, Apeak, Bpeak, DaysToWarningAvg, DaysToCriticalAvg, DaysToCapacityAvg, DaysToWarningPeak, DaysToCriticalPeak, DaysToCapacityPeak, InstanceUri, DetailsUrl, DisplayName, Description, InstanceType, Uri, InstanceSiteId
FROM Orion.ForecastCapacity
where nodeid=%s';



=item * my $sql=$self->SWQL_GetNodePollers;

=cut

use constant SWQL_GetNodePollers=>q{SELECT Description, DisplayName, Enabled, InstanceType, NetObject, NetObjectID, NetObjectType, PollerID, PollerType, Uri FROM Orion.Pollers where NetObjectID=%s and NetObjectType='%s'};

=back

=head2 Query Drivers For: Net::SolarWinds::REST::Batch

=over 4

=item * my $sql=$self->SWQL_getPollerInterfaceMap;

=item * my $sql=$self->SWQL_GetNodeInterfacePollers;

=item * my $sql=$self->SWQL_get_poller_map;

=cut 

use constant SWQL_getPollerInterfaceMap=>q{select
    p.PollerType,
    i.interfacetype as ifType,
    count(i.interfaceid) as totalinterfaces
    FROM
    Orion.NPM.Interfaces as i
    inner join Orion.Pollers as p on i.InterfaceID=p.NetObjectID and p.NetObjectType='I'
    where
    i.NodeID=%s
    group by p.PollerType,i.interfacetype};


use constant SWQL_GetNodeInterfacePollers=>q{select
    p.PollerType,
    i.interfacetype as ifType,
    i.InterfaceName as ifName,
    i.InterfaceID,
    i.Uri as InterfaceUri,
    p.Uri as PollerUri
    FROM
    Orion.NPM.Interfaces as i
    left join Orion.Pollers as p on i.InterfaceID=p.NetObjectID and p.NetObjectType='I'
    where
    i.NodeID=%s
    order by i.InterfaceID};


use constant SWQL_get_poller_map=>q{SELECT Description, DisplayName, Enabled, InstanceType, NetObject, NetObjectID, NetObjectType, PollerID, PollerType, Uri FROM Orion.Pollers where NetObjectID=%s and NetObjectType='%s'};

=back

=head1 Author

Michael Shipper

=cut

1;

__END__
