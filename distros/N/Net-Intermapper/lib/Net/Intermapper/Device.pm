package Net::Intermapper::Device;
use strict;
use Moose;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @HEADERS);
    $VERSION     = '0.04';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
	
	@HEADERS = qw(MapName MapPath Address Id Name Probe Comment Community DisplayIfUnNumbered DNSName IgnoreIfAppleTalk IgnoreIfDiscards IgnoreIfErrors IgnoreOutages AllowPeriodicProbe IMProbe Latitude Longtitude
LastTimeDown LastTimeSysUp LastTimeUp MACAddress MapAs MapId MaxTries NetBiosName PctLoss ShortTermPctLoss Availability PollInterval Port Resolve RoundTripTime SNMPv3AuthPassword SNMPv3AuthProtocol
SNMPv3PrivPassword SNMPv3PrivProtocol SNMPv3UserName SNMPVersion Status StatusLevel StatusLevelReason SysDescr SysName SysContact SysLocation SysObjectID TimeOut IMID Type ProbeXML SNMPVersionInt
SysServices EntServialNum EntMfgName EntModelName DataRetentionPolicy CustomerNameReference EnterpriseID DeviceKind SysUpTime LastModified Parent Acknowledge AckMessage AckExpiration AckTimer VertexID Layer2);

};

# MOOSE!

# I'm lazy.. Yes, there were auto-generated!		   
has 'MapName' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },
  );

has 'MapPath' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "/" },	  
  );

has 'Address' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'Id' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'Name' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'Probe' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "Ping/Echo" }, # SNMP Traffic
  );

has 'Comment' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'Community' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "public" },	  	  
  );

has 'DisplayIfUnNumbered' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "false" },
  );

has 'DNSName' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'IgnoreIfAppleTalk' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'IgnoreIfDiscards' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },
  );

has 'IgnoreIfErrors' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'IgnoreOutages' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'AllowPeriodicProbe' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'IMProbe' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'Latitude' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'Longtitude' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'LastTimeDown' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'LastTimeSysUp' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'LastTimeUp' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'MACAddress' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'MapAs' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'MapId,' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },
  );

has 'MaxTries' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'NetBiosName' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'PctLoss' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'ShortTermPctLoss' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'Availability' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'PollInterval' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'Port' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'Resolve' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'RoundTripTime' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'SNMPv3AuthPassword' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'SNMPv3AuthProtocol' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'SNMPv3PrivPassword' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'SNMPv3PrivProtocol' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'SNMPv3UserName' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'SNMPVersion' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'Status' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'StatusLevel' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'StatusLevelReason' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'SysDescr' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'SysName' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'SysContact' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'SysLocation' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'SysObjectID' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'TimeOut' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'IMID' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'Type' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'ProbeXML' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'SNMPVersionInt' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'SysServices' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'EntServialNum' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'EntMfgName' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'EntModelName' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'DataRetentionPolicy' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'CustomerNameReference' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'EnterpriseID' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'DeviceKind' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'SysUpTime' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'LastModified' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'Parent' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'Acknowledge' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'AckMessage' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'AckExpiration' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'AckTimer' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  
  );

has 'VertexID' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'Layer2' => (
      is  => 'rw',
      isa => 'Str',
	  default => sub { "" },	  	  
  );

has 'mode' => ( # create, update, delete
	is => 'rw',
	isa => 'Str',
	default => sub { "create"; },
	);
  
# No Moose	
	
sub toXML
{ my $self = shift;
  my $id = shift;
  my $result;
 # Need to build the XML formatting!!
  if ($id) { $result = "   <id>$id</id>\n"; }
return $result;
}
	
sub toCSV 
{ my $self = shift;
  my $id = $self->Id;
  my $result = "";
  my @attributes = $self->meta->get_all_attributes;
  my %attributes = ();
  for my $attribute (@attributes)
  { $attributes{$attribute->name} = $attribute->get_value($self) || "";
  }
  for my $key (@HEADERS)
  { if ($self->mode eq "create")
    { next if $key eq "Id";
	  next if $key eq "mode";
	  next if $key eq "LastTimeDown";
	  next if $key eq "LastTimeSysUp";
	  next if $key eq "LastTimeUp";
	  next unless $attributes{$key};
      $result .= $attributes{$key}.","; 
	}
	if ($self->mode eq "update")
    { next if $key eq "mode";
	  next if $key eq "LastTimeDown";
	  next if $key eq "LastTimeSysUp";
	  next if $key eq "LastTimeUp";
	  $result .= $attributes{$key}.","; 
	}
	if ($self->mode eq "delete")
    { next if $key eq "mode";
	  next unless $attributes{$key};
	  $result .= $attributes{$key}.","; 
	}

  }
  chop $result; # Remove the comma of the last field
  $result =~ s/\s$//g;
  $result .= "\r\n";
  return $result;
}

sub toTAB
{ my $self = shift;
  my $id = $self->Id;
  my $result = "";
  my @attributes = $self->meta->get_all_attributes;
  my %attributes = ();
  for my $attribute (@attributes)
  { $attributes{$attribute->name} = $attribute->get_value($self) || "";
  }
  for my $key (@HEADERS)
  { if ($self->mode eq "create")
    { next if $key eq "Id";
	  next if $key eq "mode";
	  next if $key eq "MapId";
	  next if $key eq "LastTimeDown";
	  next if $key eq "LastTimeSysUp";
	  next if $key eq "LastTimeUp";
	  next unless $attributes{$key};
	  $result .= $attributes{$key}."\t"; 
	}
	if ($self->mode eq "update")
    { next if $key eq "mode";
	  next unless $attributes{$key};
	  $result .= $attributes{$key}."\t"; 
	}
	if ($self->mode eq "delete")
    { next if $key eq "mode";
	  next unless $attributes{$key};
	  $result .= $attributes{"Id"}."\t"; 
	  last;
	}
	
  }
  chop $result; # Remove the comma of the last field
  $result =~ s/\s$//g;
  $result .= "\r\n";
  return $result;
}

sub header
{ my $self = shift;
  my $format = shift || "";
  my $header = "# format=$format table=devices fields="; 
  my @attributes = $self->meta->get_all_attributes;
  my %attributes = ();
  for my $attribute (@attributes)
  { $attributes{$attribute->name} = $attribute->get_value($self) || "";
  }
  for my $key (@HEADERS)
  { if ($self->mode eq "create")
    { next if $key eq "Id";
	  next if $key eq "mode";
	  next if $key eq "LastTimeDown";
	  next if $key eq "LastTimeSysUp";
	  next if $key eq "LastTimeUp";
	  next unless $attributes{$key};
	  $header .= $key.",";
	}
	if ($self->mode eq "update")
    { next if $key eq "LastTimeDown";
	  next if $key eq "LastTimeSysUp";
	  next if $key eq "LastTimeUp";
	  next if $key eq "mode";
	  next unless $attributes{$key};
      $header .= $key.","; 
	}
	if ($self->mode eq "delete")
    { next if $key eq "LastTimeDown";
	  next if $key eq "LastTimeSysUp";
	  next if $key eq "LastTimeUp";
	  next if $key eq "mode";
	  next unless $attributes{$key};
      $header .= $key.","; 
	}
  }
  if ($self->mode eq "delete")
  { $header .= " delete=Id,Address,Name "; } # These 3 fields are used for filtering
  chop $header; 
  $header .= "\r\n";
  return $header;
}

	
=pod

=head1 NAME

Net::Intermapper::Device - Interface with the HelpSystems Intermapper HTTP API - Devices 

=head1 SYNOPSIS

  use Net::Intermapper;
  my $intermapper = Net::Intermapper->new(hostname=>"10.0.0.1", username=>"admin", password=>"nmsadmin");
  # Options:
  # hostname - IP or hostname of Intermapper 5.x and 6.x server
  # username - Username of Administrator user
  # password - Password of user
  # ssl - SSL enabled (1 - default) or disabled (0)
  # port - TCP port for querying information. Defaults to 8181
  # modifyport - TCP port for modifying information. Default to 443
  # cache - Boolean to enable smart caching or force network queries

  my %users = $intermapper->users;
  my $users_ref = $intermapper->users;
  # Retrieve all users from Intermapper, Net::Intermapper::User instances
  # Returns hash or hashref, depending on context
  
  my %devices = $intermapper->devices;
  my $devices_ref = $intermapper->devices;
  # Retrieve all devices from Intermapper, Net::Intermapper::Device instances
  # Returns hash or hashref, depending on context

  my %maps = $intermapper->maps;
  my $maps_ref = $intermapper->maps;
  # Retrieve all maps from Intermapper, Net::Intermapper::Map instances
  # Returns hash or hashref, depending on context

  my %interfaces = $intermapper->interfaces;
  my $interfaces_ref = $intermapper->interfaces;
  # Retrieve all interfaces from Intermapper, Net::Intermapper::Interface instances
  # Returns hash or hashref, depending on context

  my %vertices = $intermapper->vertices;
  my $vertices_ref = $intermapper->vertices;
  # Retrieve all vertices from Intermapper, Net::Intermapper::Vertice instances
  # Returns hash or hashref, depending on context

  my $user = $intermapper->users->{"admin"};
  
  # Each class will generate specific header. These are typically only for internal use but are compliant to the import format Intermapper uses.
  print $user->header; 
  print $device->header;
  print $map->header;
  print $interface->header;
  print $vertice->header;

  print $user->toTAB;
  print $device->toXML; # This one is broken still!
  print $map->toCSV;
  # Works on ALL subclasses
  # Produce human-readable output of each record in the formats Intermapper supports
  
  my $user = Net::Intermapper::User->new(Name=>"testuser", Password=>"Test12345");
  my $response = $intermapper->create($user);
  # Create new user
  # Return value is HTTP::Response object
  
  my $device = Net::Intermapper::Device->new(Name=>"testDevice", MapName=>"TestMap", MapPath=>"/TestMap", Address=>"10.0.0.1");
  my $response = $intermapper->create($device);
  # Create new device
  # Return value is HTTP::Response object

  $user->Password("Foobar123");
  my $response = $intermapper->update($user);
  # Update existing user
  # Return value is HTTP::Response object

  my $user = $intermapper->users->{"bob"};
  my $response = $intermapper->delete($user);
  # Delete existing user
  # Return value is HTTP::Response object

  my $device = $intermapper->devices->{"UniqueDeviceID"};
  my $response = $intermapper->delete($device);
  # Delete existing device
  # Return value is HTTP::Response object

  my $users = { "Tom" => $tom_user, "Bob" => $bob_user };
  $intermapper->users($users);
  # At this point, there is no real reason to do this as update, create and delete work with explicit arguments.
  # But it can be done with users, devices, interfaces, maps and vertices
  # Pass a hashref to each method. This will NOT affect the smart-caching (only explicit calls to create, update and delete do this - for now).
   
=head1 DESCRIPTION

Net::Intermapper::Device is a perl wrapper around the HelpSystems Intermapper API provided through HTTP/HTTPS for access to device information.

All calls are handled through an instance of the L<Net::Intermapper> class.

  use Net::Intermapper;
  my $intermapper = Net::Intermapper->new(hostname => '10.0.0.1', username => 'admin', password => 'nmsadmin');

=head1 USAGE

=over 3

=item new

Class constructor. Returns object of Net::Intermapper::Device on succes. Attributes are:

=over 5

=item MapName (read-only)

Name of the map containing the device.

=item MapPath (read-only)

Full path of the map containing the device, including the name of the map.

=item Address (read-write)

The IP or AppleTalk address of the device that is probed by InterMapper. The IP address is represented in dotted-decimal notation, e.g. 'a.b.c.d'. The AppleTalk address is represented in slash notation, e.g. 'a/b'.

=item Id (read-only)

A unique, persistent identifier for this device instance. The Id will be unique across all maps on a single InterMapper server. This value is used for lookups in the C<users> method in L<Net::Intermapper>.

=item Name (read-only)

The name of the device. The name is the first non-empty line in a device's label on a map.

=item Probe (read-write)

The human-readable name of the InterMapper probe.

=item Comment (read-write)

The comment associated with the device.

=item Community (read-write)

The SNMP community of the device.

=item DisplayIfUnNumbered (read-write)

True if the device's behaviour is set to display unnumbered interfaces.

=item DNSName (read-write)

The fully-qualified DNS name of the device.

=item IgnoreIfAppleTalk (read-write)

True if the device's behaviour is to ignore AppleTalk interface information.

=item IgnoreIfDiscards (read-write)

True if the device's behaviour is to ignore interface discards.

=item IgnoreIfErrors (read-write)

True if the device's behaviour is to ignore interface errors.

=item IgnoreOutages (read-write)

True if the device's behaviour is to ignore outages.

=item AllowPeriodicReprobe (read-write)

True if the device's behaviour is to allow periodic reprobe.

=item IMProbe (read-write)

A special URL representation describing the InterMapper probe and its parameters, e.g. improbe://address:port/...

=item Latitude (read-write)

The latitude of the device. The value will be a double within the range [-90..90] or empty string if the device does not have this attribute set.

=item Longitude (read-write)

The longitude of the device. The value will be a double within the range [-180..180] or empty string if the device does not have this attribute set.

=item LastTimeDown (read-only)

The time when the device last went down. Value is 0 if device has not gone down since we started monitoring it.

=item LastTimeSysUp (read-only)

The time when the device last came up (ie rebooted), based on the value of sysUpTime. The value is 0 if unknown.

=item LastTimeUp (read-only)

The time when the device status last transitioned from DOWN to UP. Value is 0 if this has not happened since we started monitoring.

=item MACAddress (read-only)

The device's MAC Address. If the device has multiple interfaces, this field will contain the MAC Address associated with the device's main IP Address (the same address in the address field).

=item MapAs (read-write)

Value is one of { ROUTER , SWITCH , HUB, END SYSTEM }

=item MapId (read-only)

The unique Id of the map file containing the device.

=item MaxTries (read-write)

The maximum number of attempts to reach the device, typically indicates the maximum number of packets to send during each poll, for packet-based probes.

=item NetBIOSName (read-write)

The NetBIOS/WINS name of the device.

=item PctLoss (read-only)

The percent loss (# packets lost/total # packets sent).

=item ShortTermPctLoss (read-only)

The short-term percent loss (# packets lost/# packets sent).

=item Availability (read-only)

The percent availability (time up/time monitored).

=item PollInterval (read-write)

The poll interval of the device, in seconds. Value is 0 if non-polling.

=item Port (read-write)

The UDP or TCP port number. If the port number is not applicable, this value is always 0. (e.g. for ICMP)

=item Resolve (read-write)

Value is one of { name , addr , none }.

=item RoundTripTime (read-only)

The last round-trip time in milliseconds, if known.

=item SNMPv3AuthPassword (read-write)

The device's SNMPv3 authentication password.

=item SNMPv3AuthProtocol (read-write)

The device's SNMPv3 authentication protocol (MD5, SHA, None).

=item SNMPv3PrivPassword (read-write)

The device's SNMPv3 privacy password.

=item SNMPv3PrivProtocol (read-write)

The device's SNMPv3 privacy protocol (DES, None).

=item SNMPv3UserName (read-write)

The device's SNMPv3 user name.

=item SNMPVersion (read-write)

The device's SNMP version (SNMPv1, SNMPv2c, or SNMPv3).

=item Status (read-only)

The status of the device. The value is one of { 'UP', 'DOWN', 'UNKNOWN' }.

=item StatusLevel (read-only)

The status level of the device. The value is one of { 'Unknown', 'OK', 'Warning, Acked', 'Warning', 'Alarm, Acked', 'Alarm', 'Critical', 'Critical, Acked', 'Down', 'Down, Acked'}.

=item StatusLevelReason (read-only)

The reason the device has its status level.

=item SysDescr (read-only)

The value of sysDescr.

=item SysName (read-only)

The value of sysName.

=item SysContact (read-only)

The value of sysContact.

=item SysLocation (read-only)

The value of sysLocation.

=item SysObjectID (read-only)

The value of sysObjectID.

=item TimeOut (read-write)

The timeout of the device, in seconds. Value is 0 if not-applicable to the probe.

=item IMID (read-only)

Identifier of the device in the IMID format.

=item Type (read-only)

One of { none, other, snmp, tcp, udp, icmp, cmd, bigbro, ntsvcs }. These values have been updated in 5.0 to match the values used by the database in the probekind field of the devices table.

=item ProbeXML (read-only)

XML dataset DTD, type='probe'.

=item SNMPVersionInt (read-only)

1, 2, 3 - SNMP versions. 0 for non-SNMP.

=item SysServices (read-only)

16-bits integer.

=item EntSerialNum (read-only)

SnmpAdminString (entPhysicalSerialNum of chassis).

=item EntMfgName (read-only)

SnmpAdminString (entPhysicalMfgName of chassis).

=item EntModelName (read-only)

SnmpAdminString (entPhysicalModelName of chassis).

=item DataRetentionPolicy (read-only)

Data retention policy for IM Database

=item CustomerNameReference (read-only)

Customer-supplied device name reference, for linking to an external database.

=item EnterpriseID (read-only)

The value of sysEnterpriseID.

=item DeviceKind (read-only)

User-specified device type.

=item SysUpTime (read-only)

System uptime.

=item LastModified (read-only)

Timestamp of last modification to this device.

=item Parent (read-only)

Device ID of the parent probe group; this device's id if this device is a probe group; 0 if the device is not part of a probe group.

=item Acknowledge (read-write)

The acknowledgement state of the device; one of { 'None', 'Basic', 'Maintenance' }. The AckMessage field must also be set to import this field. Indefinite maintenance will be set if AckExpiration is missing and state is set to 'Maintenance'.

=item AckMessage (read-write)

The message associated with the acknowledge state. If Acknowledge is not set and an AckMessage is supplied, Acknowledge will be set to 'Basic'.

=item AckExpiration (read-write)

The absolute time when the timed acknowledgement expires, if any. The AckMessage field must also be set to import this field. Acknowledge will be set to 'Maintenance' if not supplied.

=item AckTimer (read-only)

The time in seconds remaining until the timed acknowledgement expires, if any.

=item VertexId (read-only)

The Vertex Id of the vertex associated with the device. Matches the VertexId of the corresponding vertex in the vertices table.

=item Layer2 (read-only)

True if layer2 mapping is enabled for this device.

=back

=over 3

=item header

Returns the C<directive> aka data header required by the Intermapper API to perform CRUD actions. This is handled through the C<create>, C<update> and C<delete> method and should not really be used.

=back

=over 3 

=item toTAB

Returns the object data formatted in TAB delimited format. Used in combination with the C<header> and the C<format> method in L<Net::Intermapper> to perform CRUD actions. This is handled through the C<create>, C<update> and C<delete> method and should not really be used.

=back

=over 3

=item toCSV

Returns the object data formatted in Comma Separated delimited format. Used in combination with the C<header> and the C<format> method in L<Net::Intermapper> to perform CRUD actions. This is handled through the C<create>, C<update> and C<delete> method and should not really be used.

=back

=over 3

=item toXML

Returns the object data formatted in XML format. Used in combination with the C<header> and the C<format> method in L<Net::Intermapper> to perform CRUD actions. This is handled through the C<create>, C<update> and C<delete> method and should not really be used.

=back

=over 3

=item mode

Internal method to properly format the data and header for CRUD actions. Typically not used.

=back

=item $ERROR

NEEDS TO BE ADDED

This variable will contain detailed error information.	
	
=back

=head1 REQUIREMENTS

For this library to work, you need an instance with Intermapper (obviously) or a simulator like L<Net::Intermapper::Mock>. 

=over 3

=item L<Moose>

=item L<IO::Socket::SSL>

=item L<LWP::UserAgent>

=item L<XML::Simple>

=item L<MIME::Base64>

=item L<URI::Escape>

=item L<Text::CSV_XS>

=back
	
=head1 BUGS

None so far

=head1 SUPPORT

None so far :)

=head1 AUTHOR

    Hendrik Van Belleghem
    CPAN ID: BEATNIK
    hendrik.vanbelleghem@gmail.com

=head1 COPYRIGHT

This program is free software licensed under the...

	The General Public License (GPL)
	Version 2, June 1991

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<http://download.intermapper.com/docs/UserGuide/Content/09-Reference/09-05-Advanced_Importing/the_directive_line.htm> 
L<http://download.intermapper.com/schema/imserverschema.html>

=cut

#################### main pod documentation end ###################

__PACKAGE__->meta->make_immutable();

1;
# The preceding line will help the module return a true value

