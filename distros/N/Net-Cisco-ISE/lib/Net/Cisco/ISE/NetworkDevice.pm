package Net::Cisco::ISE::NetworkDevice;
use strict;
use Moose;
use Data::Dumper;


BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %actions);
    $VERSION     = '0.06';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
};

    %actions = (	"query" => "/ers/config/networkdevice/",
			"create" => "/ers/config/networkdevice/",
               		"update" => "/ers/config/networkdevice/",
                	"getById" => "/ers/config/networkdevice/",
           ); 

# MOOSE!		   

has 'id' => (
     is  => 'rw',
     isa => 'Str',
  );

has 'name' => (
	is => 'rw',
	isa => 'Str',
	);
has 'description' => (
	is => 'rw',
	isa => 'Str',
);

has 'authenticationSettings' => (
	is => 'rw',
	isa => 'Any',
);

has 'coaPort' => (
	is => 'rw',
	isa => 'Str',
	default => '1700',
);

has 'profileName' => (
	is => 'rw',
	isa => 'Str',
);

has 'NetworkDeviceIPList' => (
	is => 'rw',
	isa => 'Any',
);

has 'NetworkDeviceGroupList' => (
	is => 'rw',
	isa => 'Any',
);

has 'modelName' => (
	is => 'rw',
	isa => 'Str',
);

has 'ProfileName' => (
	is => 'rw',
	isa => 'Str',
);

has 'softwareVersion' => (
	is => 'rw',
	isa => 'Str',
); 

has 'snmpsettings' => (
	is => 'rw',
	isa => 'Any',
);

has 'tacacsSettings' => (
	is => 'rw',
	isa => 'Any',
);

has 'trustsecsettings' => (
	is => 'rw',
	isa => 'Any',
);

# No Moose	

sub toXML
{ my $self = shift;
  my $result = "";
  my $id = $self->id || "";
  my $name = $self->name || "";
  my $description = $self->description || "";
  if ($self->authenticationSettings)
  { my $enablekeywrap = $self->authenticationSettings->{"enablekeywrap"} || "";
    my $keyencryptionkey = $self->authenticationSettings->{"keyencryptionkey"} || "";
    my $keyinputformat = $self->authenticationSettings->{"keyInputFormat"} || "";
    my $messageauthenticatorcodekey = $self->authenticationSettings->{"messageAuthenticatorCodeKey"} || "";
    my $networkprotocol = $self->authenticationSettings->{"networkProtocol"} || "";
    my $radiussharedsecret = $self->authenticationSettings->{"radiusSharedSecret"} || "";
    $result .= <<XML;
<authenticationSettings>
<enableKeyWrap>$enablekeywrap</enableKeyWrap>
<keyEncryptionKey>$keyencryptionkey</keyEncryptionKey>
<keyInputFormat>$keyinputformat</keyInputFormat>
<messageAuthenticatorCodeKey>$messageauthenticatorcodekey</messageAuthenticatorCodeKey>
<networkProtocol>$networkprotocol</networkProtocol>
<radiusSharedSecret>$radiussharedsecret</radiusSharedSecret>
</authenticationSettings>
XML

  } 
  my $coaport = $self->coaPort || "";
  $result .= "<coaPort>$coaport</coaPort>\n";
  if ($self->NetworkDeviceIPList) 
  { $result .= "<NetworkDeviceIPList>\n"; 
    my @networkdeviceiplist = @{ $self->NetworkDeviceIPList->{"NetworkDeviceIP"} };
    for my $networkdeviceiplist (@networkdeviceiplist)
    { my $ipaddress = $networkdeviceiplist->{"ipaddress"} || "";
      my $mask = $networkdeviceiplist->{"mask"} || "";
      $result .= <<XML;
<NetworkDeviceIP>
<ipaddress>$ipaddress</ipaddress>
<mask>$mask</mask>
</NetworkDeviceIP>
XML
    }
  $result .= "</NetworkDeviceIPList>\n"; 
  }
  
  if ($self->NetworkDeviceGroupList) 
  { $result .= "<NetworkDeviceGroupList>\n"; 
    my @networkdevicegrouplist = @{ $self->NetworkDeviceGroupList->{"NetworkDeviceGroup"} };
    for my $networkdevicegroup (@networkdevicegrouplist)
    { my $name = $networkdevicegroup || "";
      $result .= qq(<NetworkDeviceGroup>$name</NetworkDeviceGroup>\n);
    }
    $result .= "</NetworkDeviceGroupList>\n"; 
  }
  my $profilename = $self->profileName || "";
  $result .= "<profileName>$profilename</profileName>";
  if ($self->snmpsettings)
  { $result .= "<snmpsettings>\n";
    my $linktrapquery = $self->snmpsettings->{"linkTrapQuery"} || "";
    my $mactrapquery = $self->snmpsettings->{"macTrapQuery"} || "";
    my $originatingpolicyservicesnode = $self->snmpsettings->{"originatingPolicyServicesNode"} || "";
    my $pollinginterval = $self->snmpsettings->{"pollingInterval"} || "";
    my $rocommunity = $self->snmpsettings->{"roCommunity"} || "";
    my $version = $self->snmpsettings->{"version"} || "";
    my $authpassword = $self->snmpsettings->{"authPassword"} || "";
    my $privacyprotocol = $self->snmpsettings->{"privacyProtocol"} || "";
    my $securitylevel = $self->snmpsettings->{"securityLevel"} || ""; 
    my $authprotocol = $self->snmpsettings->{"authProtocol"} || "";
    my $username = $self->snmpsettings->{"userName"} || "";
    my $privacypassword = $self->snmpsettings->{"privacyPassword"} || "";
      $result .= <<XML;
<snmpsettings>
<linkTrapQuery>$linktrapquery</linkTrapQuery>
<macTrapQuery>$mactrapquery</macTrapQuery>
<originatingPolicyServicesNode>$originatingpolicyservicesnode</originatingPolicyServicesNode>
<pollingInterval>$pollinginterval</pollingInterval>
<roCommunity>$rocommunity</roCommunity>
<version>$version</version>
<authPassword>$authpassword</authPassword>
<privacyProtocl>$privacyprotocol</privacyProtocol>
<securityLevel>$securitylevel</securityLevel>
<authProtocol>$authprotocol</authProtocol>
<userName>$username</userName>
<privacyPassword>$privacypassword</privacyPassword>
</snmpsettings>
XML
  }

 if ($self->tacacsSettings)
 { my $connectmodeoptions = $self->tacacsSettings->{"connectModeOptions"} || "";
   my $sharedsecret = $self->tacacsSettings->{"sharedSecret"} || "";
   $result .= <<XML;
<tacacsSettings>
<connectModeOptions>$connectmodeoptions</connectModeOptions>
<sharedSecret>$sharedsecret</sharedSecret>
</tacacsSettings>
XML

  }

if ($self->trustsecsettings)
{ $result .= qq(<trustsecsettings>);
  if ($self->trustsecsettings->{"deviceAuthenticationSettings"})
  { my $sgadeviceid = $self->trustsecsettings->{"deviceAuthenticationSettings"}{"sgaDeviceId"} || "";
    my $sgadevicepassword = $self->trustsecsettings->{"deviceAuthenticationSettings"}{"sgaDevicePassword"} || "";
    $result .= qq(<deviceAuthenticationSettings>\n);
    $result .= qq(<sgaDeviceId>$sgadeviceid</sgaDeviceId>\n); 
    $result .= qq(<sgaDevicePassword>$sgadevicepassword</sgaDevicePassword>\n);
    $result .= qq(</deviceAuthenticationSettings>\n);
  }
  if ($self->trustsecsettings->{"sgaNotificationAndUpdates"})
  { my $sendconfigurationtodeviceusing = $self->trustsecsettings->{"sgaNotificationAndUpdates"}{"sendConfigurationToDeviceUsing"} || "";
    my $downloadpeerauthorizationpolicyeveryxseconds = $self->trustsecsettings->{"sgaNotificationAndUpdates"}{"downlaodPeerAuthorizationPolicyEveryXSeconds"} || "";
    $downloadpeerauthorizationpolicyeveryxseconds ||= $self->trustsecsettings->{"sgaNotificationAndUpdates"}{"downloadPeerAuthorizationPolicyEveryXSeconds"} || ""; 
    my $downloadsgaccllistseveryxseconds = $self->trustsecsettings->{"sgaNotificationAndUpdates"}{"downloadSGACLListsEveryXSeconds"} || "";
    my $downloadenvironmentdataeveryxseconds = $self->trustsecsettings->{"sgaNotificationAndUpdates"}{"downlaodEnvironmentDataEveryXSeconds"} || "";
    $downloadenvironmentdataeveryxseconds ||= $self->trustsecsettings->{"sgaNotificationAndUpdates"}{"downloadEnvironmentDataEveryXSeconds"} || "";
    my $reauthenticationeveryxseconds = $self->trustsecsettings->{"sgaNotificationAndUpdates"}{"reAuthenticationEveryXSeconds"} || "";
    my $sendconfigurationtodevice = $self->trustsecsettings->{"sgaNotificationAndUpdates"}{"sendConfigurationToDevice"} || ""; 
    my $othersgadevicestotrustthisdevice = $self->trustsecsettings->{"sgaNotificationAndUpdates"}{"otherSGADevicesToTrustThisDevice"} || "";

    $result .= qq(<sgaNotificationAndUpdates>\n);
    $result .= qq(<sendConfigurationToDeviceUsing>$sendconfigurationtodeviceusing</sendConfigurationToDeviceUsing>\n);
    $result .= qq(<downlaodPeerAuthorizationPolicyEveryXSeconds>$downloadpeerauthorizationpolicyeveryxseconds</downlaodPeerAuthorizationPolicyEveryXSeconds>\n);
    $result .= qq(<downlaodEnvironmentDataEveryXSeconds>$downloadenvironmentdataeveryxseconds</downlaodEnvironmentDataEveryXSeconds>\n);
    $result .= qq(<reAuthenticationEveryXSeconds>$reauthenticationeveryxseconds</reAuthenticationEveryXSeconds>\n);
    $result .= qq(<sendConfigurationToDevice>$sendconfigurationtodevice</sendConfigurationToDevice>\n);
    $result .= qq(<otherSGADevicesToTrustThisDevice>$othersgadevicestotrustthisdevice</otherSGADevicesToTrustThisDevice>\n);
    $result .= qq(<downloadSGACLListsEveryXSeconds>$downloadsgaccllistseveryxseconds</downloadSGACLListsEveryXSeconds>\n);
    $result .= qq(</sgaNotificationAndUpdates>\n);
  }
  if ($self->trustsecsettings->{"deviceConfigurationDeployment"})
  { my $includewhendeployingsgtupdates =  $self->trustsecsettings->{"deviceConfigurationDeployment"}{"includeWhenDeployingSGTUpdates"} || "";
    my $execmodeusername = $self->trustsecsettings->{"deviceConfigurationDeployment"}{"execModeUsername"} || "";
    my $enablemodepassword = $self->trustsecsettings->{"deviceConfigurationDeployment"}{"enableModePassword"} || "";
    my $execmodepassword = $self->trustsecsettings->{"deviceConfigurationDeployment"}{"execModePassword"} || "";

    $result .= qq(<deviceConfigurationDeployment>\n);
    $result .= qq(<includeWhenDeployingSGTUpdates></includeWhenDeployingSGTUpdates>\n);
    $result .= qq(<execModeUsername>$execmodeusername</execModeUsername>\n);
    $result .= qq(<enableModePassword>$enablemodepassword</enableModePassword>\n);
    $result .= qq(<execModePassword>$execmodepassword</execModePassword>\n);
    $result .= qq(</deviceConfigurationDeployment>\n);
  }

  $result .= qq(</trustsecsettings>\n);
}
# Not documented by Cisco ISE API:
# SNMP Settings: authPassword
# SNMP Settings: privacyProtocol
# SNMP Settings: securityLevel
# SNMP Settings: authProtocol
# SNMP Settings: userName
# SNMP Settings: privacyPassword
# TACACS Settings: previousSharedSecretExpiry - Probably not implemented for write operations
# TACACS Settings: previousSharedSecret - Probably not implemented for write operations

  return $result;
}

sub header
{ my $self = shift;
  my $data = shift;
  my $record = shift;
  my $name = $record->name || "Device Name";
  my $id = $record->id || "";
  my $description = $record->description || "Random Description";

  return qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns4:networkdevice description="$description" name="$name" id="$id" xmlns:ers="ers.ise.cisco.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ns4="network.ers.ise.cisco.com">$data</ns4:networkdevice>};

}

=pod

=head1 NAME

Net::Cisco::ISE::Device - Access Cisco ISE functionality through REST API - Device fields

=head1 SYNOPSIS

	use Net::Cisco::ISE;
	use Net::Cisco::ISE::Device;
	
	my $ise = Net::Cisco::ISE->new(hostname => '10.0.0.1', username => 'acsadmin', password => 'testPassword');
	
	my %devices = $ise->devices;
	# Retrieve all devices from ISE
	# Returns hash with device name / Net::Cisco::ISE::Device pairs

	print $ise->devices->{"MAIN_Router"}->toXML;
	# Dump in XML format (used by ISE for API calls)
	
	my $device = $ise->devices("name","MAIN_Router");
	# Faster call to request specific device information by name

	my $device = $ise->devices("id","250");
	# Faster call to request specific device information by ID (assigned by ISE, present in Net::Cisco::ISE::Device)

	$device->id(0); # Required for new device!
	my $id = $ise->create($device);
	# Create new device based on Net::Cisco::ISE::Device instance
	# Return value is ID generated by ISE
	print "Record ID is $id" if $id;
	print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure

	my $id = $ise->update($device);
	# Update existing device based on Net::Cisco::ISE::Device instance
	# Return value is ID generated by ISE
	print "Record ID is $id" if $id;
	print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure

	$ise->delete($device);
	# Delete existing device based on Net::Cisco::ISE::Device instance

=head1 DESCRIPTION

The Net::Cisco::ISE::Device class holds all the device relevant information from Cisco ISE 5.x

=head1 USAGE

All calls are typically handled through an instance of the L<Net::Cisco::ISE> class. L<Net::Cisco::ISE::Device> acts as a container for device group related information.

=over 3

=item new

Class constructor. Returns object of Net::Cisco::ISE::Device on succes. The following fields can be set / retrieved:

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

Formatting rules may be in place & enforced by Cisco ISE.

=over 3

=item description

The device description.

=item id

The device ID. Cisco ISE generates a unique ID for each Host record. This field cannot be updated within ISE but is used for reference. Set to 0 when creating a new record or when duplicating an existing host.

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

Cleaned up instance of C<subnet>. Not yet added... be patient!

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

Dump the record in ISE accept XML formatting (without header).

=item header

Generate the correct XML header. Takes output of C<toXML> as argument.

=back

=over 3

=item description 

The device group account description, typically used for full device group name.

=item groupType

This points to the type of Device Group, typically Location or Device Type but can be customized. See also L<Net::Cisco::ISE::Device> C<deviceType>.

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

