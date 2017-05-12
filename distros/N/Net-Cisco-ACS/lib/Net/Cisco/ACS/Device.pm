package Net::Cisco::ACS::Device;
use strict;
use Moose;
use Data::Dumper;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %actions);
    $VERSION     = '0.03';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
};

    %actions = (	"query" => "/Rest/NetworkDevice/Device",
					"create" => "/Rest/NetworkDevice/Device",
               		"update" => "/Rest/NetworkDevice/Device",
                	"getByName" => "/Rest/NetworkDevice/Device/name/",
                	"getById" => "/Rest/NetworkDevice/Device/id/",
           ); 

# MOOSE!		   

has 'description' => (
      is  => 'rw',
      isa => 'Any',
  );

has 'id' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'name' => (
	is => 'rw',
	isa => 'Str',
	);

has 'tacacsConnection' => (
	is => 'rw',
	isa => 'HashRef',
	trigger => \&parseTacacsConnection,
	auto_deref => 1,
	);

sub parseTacacsConnection
{ my $self = shift;
  my $new_ref = shift;
  $self->singleConnect($self->tacacsConnection->{"singleConnect"});
  $self->tacacs_SharedSecret($self->tacacsConnection->{"sharedSecret"});
  $self->legacyTACACS($self->tacacsConnection->{"legacyTACACS"});
};

has 'groupInfo' => ( 
	isa => 'Any',
	is => 'rw',
	trigger => \&parseGroupInfo,
	);

sub parseGroupInfo # STILL TO DO: Implement non-default groups!
{ my $self = shift;
  my $new_ref = shift;
  for my $entry (@{ $new_ref })
  { if ($entry->{"groupType"} eq "Location")
    { $self->location($entry->{"groupName"});
    }
    if ($entry->{"groupType"} eq "Device Type")
    { $self->deviceType($entry->{"groupName"});
    }
  }
}
	
has 'legacyTACACS' => (
	is => 'rw',
	isa => 'Str',
	);

has 'tacacs_SharedSecret' => (
	is => 'rw',
	isa => 'Str',
	);

has 'singleConnect' => (
	is => 'rw',
	isa => 'Str',
	);

has 'radius_SharedSecret' => (
	is => 'rw',
	isa => 'Str',
	);

has 'subnets' => (
	is => 'rw',
	isa => 'Any',
	trigger => \&parseSubnet, # trigger modifier is calling within constructor
	);

sub parseSubnet
{ my $self = shift;
  my $new_ref = shift;
  my @ips = ();
  if (ref($new_ref) eq "HASH")
  { push(@ips,{ netMask => $new_ref->{"netMask"}, ipAddress => $new_ref->{"ipAddress"} }); }
  if (ref($new_ref) eq "ARRAY")
  { for my $entry (@ { $new_ref })
    { if (ref($entry) eq "HASH")
	  { push(@ips,{ netMask => $entry->{"netMask"}, ipAddress => $entry->{"ipAddress"} }); } 
	}
  }
  $self->ips([@ips]);
}

has 'ips' => (
	is => 'rw',
	isa => 'ArrayRef',
	auto_deref => 1,
	);
	
has 'location' => (
	is => 'rw',
	isa => 'Str',
	);

has 'deviceType' => (
	is => 'rw',
	isa => 'Str',
	);

has 'displayedInHex' => (
	is => 'rw',
	isa => 'Str',
	);

has 'keyWrap' => (
	is => 'rw',
	isa => 'Str',
	);

has 'portCOA' => (
	is => 'rw',
	isa => 'Str',
	);

# No Moose	

sub toXML
{ my $self = shift;
  my $result = "";
  my $id = $self->id;
  my $description = $self->description || "";
  my $name = $self->name || "";
  my $location = $self->location || "All Locations";
  my $devicetype = $self->deviceType || "All Device Types";

  my $legacytacacs = $self->legacyTACACS || "false";
  my $tacacs_sharedsecret = $self->tacacs_SharedSecret || "";  
  my $singleconnect = $self->singleConnect || "false";

  my $displayedinhex = $self->displayedInHex || "true";
  my $keywrap = $self->keyWrap || "false";
  my $portcoa = $self->portCOA || "1700";
  my $radius_sharedsecret = $self->radius_SharedSecret || "";

  $result = <<XML;
	<description>$description</description>
	<name>$name</name>
	<groupInfo>
	<groupName>$devicetype</groupName>
	<groupType>Device Type</groupType>
	</groupInfo>
	<groupInfo>
	<groupName>$location</groupName>
	<groupType>Location</groupType>
	</groupInfo>
XML

  if (ref($self->ips) eq "ARRAY")
  { for my $ref ( @{ $self->ips } )
    { my $netmask = $ref->{'netMask'};
	  my $ipaddress = $ref->{'ipAddress'};
	  $result .= <<XML;
	<subnets><ipAddress>$ipaddress</ipAddress><netMask>$netmask</netMask></subnets>
XML
	}
  }

  if ($tacacs_sharedsecret) {
  $result .= <<XML;
	<tacacsConnection>
	<legacyTACACS>$legacytacacs</legacyTACACS>
	<sharedSecret>$tacacs_sharedsecret</sharedSecret>
	<singleConnect>$singleconnect</singleConnect>
	</tacacsConnection>
XML
  }

  if ($radius_sharedsecret)
  { $result .= <<XML;
	<radiusConnection>
	<displayedInHex>$displayedinhex</displayedInHex>
	<keyWrap>$keywrap</keyWrap>
	<portCoA>$portcoa</portCoA>
	<sharedSecret>$radius_sharedsecret</sharedSecret>
	</radiusConnection>
XML
  }

  return $result;
}

sub header
{ my $self = shift;
  my $devices = shift;
  return qq(<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns1:device xmlns:ns1="networkdevice.rest.mgmt.acs.nm.cisco.com">$devices</ns1:device>);
}
	
=head1 NAME

Net::Cisco::ACS::Device - Access Cisco ACS functionality through REST API - Device fields

=head1 SYNOPSIS

	use Net::Cisco::ACS;
	use Net::Cisco::ACS::Device;
	
	my $acs = Net::Cisco::ACS->new(hostname => '10.0.0.1', username => 'acsadmin', password => 'testPassword');
	
	my %devices = $acs->devices;
	# Retrieve all devices from ACS
	# Returns hash with device name / Net::Cisco::ACS::Device pairs

	print $acs->devices->{"MAIN_Router"}->toXML;
	# Dump in XML format (used by ACS for API calls)
	
	my $device = $acs->devices("name","MAIN_Router");
	# Faster call to request specific device information by name

	my $device = $acs->devices("id","250");
	# Faster call to request specific device information by ID (assigned by ACS, present in Net::Cisco::ACS::Device)

	$device->id(0); # Required for new device!
	my $id = $acs->create($device);
	# Create new device based on Net::Cisco::ACS::Device instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $id = $acs->update($device);
	# Update existing device based on Net::Cisco::ACS::Device instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	$acs->delete($device);
	# Delete existing device based on Net::Cisco::ACS::Device instance

=head1 DESCRIPTION

The Net::Cisco::ACS::Device class holds all the device relevant information from Cisco ACS 5.x

=head1 USAGE

All calls are typically handled through an instance of the L<Net::Cisco::ACS> class. L<Net::Cisco::ACS::Device> acts as a container for device group related information.

=over 3

=item new

Class constructor. Returns object of Net::Cisco::ACS::Device on succes. The following fields can be set / retrieved:

=over 5

=item description

=item id

=item name

=item tacacsConnection

=item groupInfo 

=item legacyTACACS

=item tacacs_SharedSecret

=item singleConnect

=item radius_SharedSecret

=item subnets

=item ips

=item location

=item deviceType

=item displayedInHex

=item keyWrap

=item portCOA

=back

Formatting rules may be in place & enforced by Cisco ACS.

=over 3

=item description

The device description.

=item id

The device ID. Cisco ACS generates a unique ID for each Host record. This field cannot be updated within ACS but is used for reference. Set to 0 when creating a new record or when duplicating an existing host.

=item name

The device name, typically something like the sysName or hostname.

=item tacacsConnection

Boolean value (0 / 1) to indicate if TACACS+ is used on this device.

=item groupInfo 

Read-only value that contains C<deviceType>, C<location> and other device type information. Only C<deviceType>, C<location> are retrievable by the respective methods.

=item legacyTACACS

Boolean value (0 / 1) that indicates support for legacy versions of TACACS+.

=item tacacs_SharedSecret

The shared key for TACACS+. When retrieving this information, the key is masked as **********.

=item singleConnect

The TACACS+ singleConnect setting.

=item radius_SharedSecret

The shared key for RADIUS. When retrieving this information, the key is masked as **********.

=item subnets

Array reference that contains hash entries of all IP information for the device entry, separated as C<netMask> and C<ipAddress> keys. 

=item ips

Cleaned up instance of C<subnet>.

=item location

The device location field, as defined in C<groupInfo>.

=item deviceType

The specific device Type field.

=item displayedInHex

Boolean value (0 / 1). Used for RADIUS configuration.

=item keyWrap

Boolean value (0 / 1). Used for RADIUS configuration.

=item portCOA

TCP port for specific RADIUS purposes.

=item toXML

Dump the record in ACS accept XML formatting (without header).

=item header

Generate the correct XML header. Takes output of C<toXML> as argument.

=back

=over 3

=item description 

The device group account description, typically used for full device group name.

=item groupType

This points to the type of Device Group, typically Location or Device Type but can be customized. See also L<Net::Cisco::ACS::Device> C<deviceType>.

=back

=back

=head1 BUGS



=head1 SUPPORT



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

perl(1).

=cut

#################### main pod documentation end ###################
__PACKAGE__->meta->make_immutable();

1;
# The preceding line will help the module return a true value

