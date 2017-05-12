#--------------------------------------------------------------
# IC1500.pm
# Perl module to control Edimax IC1500-series network cameras
# (c) 2008, 2009 Andy Smith
#--------------------------------------------------------------
# $Id: IC1500.pm 8 2009-04-24 18:34:18Z andys $
#--------------------------------------------------------------
# See 'perldoc IC1500.pm' for documentation
#--------------------------------------------------------------

package Net::Camera::Edimax::IC1500;

use 5.008008;
use strict;
use warnings;

require Exporter;

use LWP::UserAgent;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Edimax ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = sprintf "1.%03d", q$Id: IC1500.pm 8 2009-04-24 18:34:18Z andys $ =~ /: .+ (\d+) \d+-/;

# Preloaded methods go here.

sub new {
	my $package = shift;
	my $self = {};
	my %options = @_;

	$self->{hostname}	= $options{hostname};
	if ($options{port}) { $self->{port} = $options{port}; } else { $self->{port} = "80"; }
	$self->{username}	= $options{username};
	$self->{password}	= $options{password};

	$self->{_ua}		= undef;

	# Image settings
	$self->{imageSettingsResolution}	= undef;
	$self->{imageSettingsQuality}	= 15; # camera_left.asp appears to set set anything as 'selected' by default
	$self->{imageSettingsFrameRate}	= undef;
	$self->{imageSettingsFrequency}	= undef;
	$self->{imageSettingsBrightness}	= undef;
	$self->{imageSettingsContrast}	= undef;
	$self->{imageSettingsSaturation}	= undef;
	$self->{imageSettingsHue}		= undef;
	$self->{imageSettingsWhiteness}	= undef;
	$self->{imageSettingsAutoExp}	= undef;

	# System settings
	$self->{systemSettingsLED}	= undef;
	$self->{systemSettingsCameraName} = undef;
	$self->{systemSettingsPassword} = undef;

	# Status settings
	$self->{statusFirmware}				= undef;
	$self->{statusUptime}				= undef;
	$self->{statusTime}					= undef;
	$self->{statusIPAddress}			= undef;
	$self->{statusNetmask}				= undef;
	$self->{statusGateway}				= undef;
	$self->{statusDNSServer}			= undef;
	$self->{statusMACAddress}			= undef;
	$self->{statusVideoPort}			= undef;
	$self->{statusHTTPPort}				= undef;

	$self = bless($self, $package);

	$self->{_ua}		= $self->_createLWP();

	return $self;
}

sub _createLWP {
	my $self = shift;

	my $ua = LWP::UserAgent->new;
	$ua->agent("Net::Camera::Edimax::IC1500/$VERSION");

	$ua->credentials(
		$self->{hostname} . ':' . $self->{port},
		'Internet Camera',
		$self->{username} => $self->{password}
	);

	return $ua;
}

sub _buildImageSettingsRequest {
	my $self = shift;
	my ($query) = @_;

	my $request = HTTP::Request->new(GET => 'http://' . $self->{hostname} . ':' . $self->{port} . '/form/camera?' . $query);

	return $request;
}

# Accessor methods

sub imageSettingsResolution {
	my $self = shift;
	my ($value) = @_;

	$self->{imageSettingsResolution}	= $value if defined($value);

	return $self->{imageSettingsResolution};
}

sub imageSettingsQuality {
	my $self = shift;
	my ($value) = @_;

	$self->{imageSettingsQuality}	= $value if defined($value);

	return $self->{imageSettingsQuality};
}

sub imageSettingsFrameRate {
	my $self = shift;
	my ($value) = @_;

	$self->{imageSettingsFrameRate}	= $value if defined($value);

	return $self->{imageSettingsFrameRate};
}

sub imageSettingsFrequency {
	my $self = shift;
	my ($value) = @_;

	$self->{imageSettingsFrequency}	= $value if defined($value);

	return $self->{imageSettingsFrequency};
}

sub imageSettingsBrightness {
	my $self = shift;
	my ($value) = @_;

	$self->{imageSettingsBrightness}	= $value if defined($value);

	return $self->{imageSettingsBrightness};
}

sub imageSettingsContrast {
	my $self = shift;
	my ($value) = @_;

	$self->{imageSettingsContrast}	= $value if defined($value);

	return $self->{imageSettingsContrast};
}

sub imageSettingsSaturation {
	my $self = shift;
	my ($value) = @_;

	$self->{imageSettingsSaturation}	= $value if defined($value);

	return $self->{imageSettingsSaturation};
}

sub imageSettingsHue {
	my $self = shift;
	my ($value) = @_;

	$self->{imageSettingsHue}	= $value if defined($value);

	return $self->{imageSettingsHue};
}

sub imageSettingsWhiteness {
	my $self = shift;
	my ($value) = @_;

	$self->{imageSettingsWhiteness}	= $value if defined($value);

	return $self->{imageSettingsWhiteness};
}

sub imageSettingsAutoExp {
	my $self = shift;
	my ($value) = @_;

	if(defined($value))
	{
		if($value eq "ON")
		{
			$self->{imageSettingsAutoExp} = $value;
		}
		else
		{
			$self->{imageSettingsAutoExp} = "";
		}
	}

	return $self->{imageSettingsAutoExp};
}

sub systemSettingsCameraName {
	my $self = shift;
	my ($value) = @_;

	$self->{systemSettingsCameraName} = $value if defined($value);

	return $self->{systemSettingsCameraName};
}

sub systemSettingsPassword {
	my $self = shift;
	my ($value) = @_;

	$self->{systemSettingsPassword} = $value if defined($value);

	return $self->{systemSettingsPassword};
}

sub systemSettingsLED {
	my $self = shift;
	my ($value) = @_;

	$self->{systemSettingsLED} = $value if defined($value);

	return $self->{systemSettingsLED};
}

sub statusFirmware {
	my $self = shift;
	my ($value) = @_;

	$self->{statusFirmware} = $value if defined($value);

	return $self->{statusFirmware};
}

sub statusUptime {
	my $self = shift;
	my ($value) = @_;

	$self->{statusUptime} = $value if defined($value);

	return $self->{statusUptime};
}

sub statusTime {
	my $self = shift;
	my ($value) = @_;

	$self->{statusTime} = $value if defined($value);

	return $self->{statusTime};
}

sub statusIPAddress {
	my $self = shift;
	my ($value) = @_;

	$self->{statusIPAddress} = $value if defined($value);

	return $self->{statusIPAddress};
}

sub statusNetmask {
	my $self = shift;
	my ($value) = @_;

	$self->{statusNetmask} = $value if defined($value);

	return $self->{statusNetmask};
}

sub statusGateway {
	my $self = shift;
	my ($value) = @_;

	$self->{statusGateway} = $value if defined($value);

	return $self->{statusGateway};
}

sub statusDNSServer {
	my $self = shift;
	my ($value) = @_;

	$self->{statusDNSServer} = $value if defined($value);

	return $self->{statusDNSServer};
}

sub statusMACAddress {
	my $self = shift;
	my ($value) = @_;

	$self->{statusMACAddress} = $value if defined($value);

	return $self->{statusMACAddress};
}

sub statusVideoPort {
	my $self = shift;
	my ($value) = @_;

	$self->{statusVideoPort} = $value if defined($value);

	return $self->{statusVideoPort};
}

sub statusHTTPPort {
	my $self = shift;
	my ($value) = @_;

	$self->{statusHTTPPort} = $value if defined($value);

	return $self->{statusHTTPPort};
}

sub setImageSettings {
	my $self = shift;
	
	# Start with a blank query
	my $query = undef;

	# Build up our query as needed
	$query  = "resolution=".$self->imageSettingsResolution;
	$query .= "&quality=".$self->imageSettingsQuality;
	$query .= "&framerate=".$self->imageSettingsFrameRate;
	$query .= "&frequency=".$self->imageSettingsFrequency;

	if($self->imageSettingsAutoExp eq "ON")
	{
		$query .= "&autoexposure=".$self->imageSettingsAutoExp;
	}

	$query .= "&b_value=".$self->imageSettingsBrightness;
	$query .= "&c_value=".$self->imageSettingsContrast;
	$query .= "&s_value=".$self->imageSettingsSaturation;
	$query .= "&h_value=".$self->imageSettingsHue;
	$query .= "&w_value=".$self->imageSettingsWhiteness;

	my $request = $self->_buildImageSettingsRequest($query);
	$self->{_ua}->request($request);
}

sub getSnapshot {
	my $self = shift;

	my $request = HTTP::Request->new(GET => 'http://' . $self->{hostname} . ':' . $self->{port} . '/snapshot.jpg');

	my $response = $self->{_ua}->request($request);

	return $response->{_content};
}

sub cycleSystemLED {
	my $self = shift;

	my $request = HTTP::Request->new(GET => 'http://' . $self->{hostname} . ':' . $self->{port} . '/form/enet?enet_source=system.asp&enet_avs_disable_leds=');

	my $response = $self->{_ua}->request($request);
}

sub reboot {
	my $self = shift;

	my $request = HTTP::Request->new(GET => 'http://' . $self->{hostname} . ':' . $self->{port} . '/form/reboot?enet_source=reboot.htm');

	my $response = $self->{_ua}->request($request);
}

sub getSystemSettings {
	my $self = shift;

	my $request = HTTP::Request->new(GET => 'http://' . $self->{hostname} . ':' . $self->{port} . '/system.asp');

	my $response = $self->{_ua}->request($request);

	my $settingsPage = $response->{_content};

	my $led;
	my $camera_name;
	my $password;

	if($settingsPage =~ /Turn (\w+) LED light/im)
	{
		if($1 eq "on")
		{
			$led = 0;
		}
		else
		{
			$led = 1;
		}
	}
	if($settingsPage =~ /enet_camera_name" value="(\w+)" size/im)
	{
		$camera_name = $1;
	}
	if($settingsPage =~ /enet_passwd" value="(\w+)" size/im)
	{
		$password = $1;
	}

	$self->systemSettingsLED($led);
	$self->systemSettingsCameraName($camera_name);
	$self->systemSettingsPassword($password);
}

sub getLog {
	my $self = shift;

	my $request = HTTP::Request->new(GET => 'http://' . $self->{hostname} . ':' . $self->{port} . '/log_show.asp');

	my $response = $self->{_ua}->request($request);

	my $logPage = $response->{_content};

	my $logFile;
	if($logPage =~ /<textarea rows="25".+?face="Arial">(.+)<\/textarea>/ms)
	{
		$logFile = $1;
	}

	return $logFile;
}

sub getStatus {
	my $self = shift;

	my $request = HTTP::Request->new(GET => 'http://' . $self->{hostname} . ':' . $self->{port} . '/status.asp');

	my $response = $self->{_ua}->request($request);

	my $statusPage = $response->{_content};

	my $firmware;
	my $uptime;
	my $time;
	my $ipaddress;
	my $netmask;
	my $gateway;
	my $dnsserver;
	my $macaddress;
	my $videoport;
	my $httpport;

	if($statusPage =~ /Firmware Version :<\/font>.+?9pt">(.+?)<\/font/ms)
	{
		$firmware = $1;
	}
	if($statusPage =~ /Device Uptime :<\/font>.+?9pt">(.+?)<\/font/ms)
	{
		$uptime = $1;
	}
	if($statusPage =~ /System Time :<\/font>.+?9pt">(.+?)<\/font/ms)
	{
		$time = $1;
	}
	if($statusPage =~ /IP Address :<\/font>.+?9pt">(.+?)<\/font/ms)
	{
		$ipaddress = $1;
	}
	if($statusPage =~ /Subnet Mask :<\/font>.+?9pt">(.+?)<\/font/ms)
	{
		$netmask = $1;
	}
	if($statusPage =~ /Gateway :<\/font>.+?9pt">(.+?)<\/font/ms)
	{
		$gateway = $1;
	}
	if($statusPage =~ /DNS Server :<\/font>.+?9pt">(.+?)<\/font/ms)
	{
		$dnsserver = $1;
	}
	if($statusPage =~ /MAC Address :<\/font>.+?9pt">(.+?)<\/font/ms)
	{
		$macaddress = $1;
	}
	if($statusPage =~ /Video Port :<\/font>.+?9pt">(.+?)<\/font/ms)
	{
		$videoport = $1;
	}
	if($statusPage =~ /HTTP Port :<\/font>.+?9pt">(.+?)<\/font/ms)
	{
		$httpport = $1;
	}

	$self->statusFirmware($firmware);
	$self->statusUptime($uptime);
	$self->statusTime($time);
	$self->statusIPAddress($ipaddress);
	$self->statusNetmask($netmask);
	$self->statusGateway($gateway);
	$self->statusDNSServer($dnsserver);
	$self->statusMACAddress($macaddress);
	$self->statusVideoPort($videoport);
	$self->statusHTTPPort($httpport);
}


sub getImageSettings {
	my $self = shift;

	my $request = HTTP::Request->new(GET => 'http://' . $self->{hostname} . ':' . $self->{port} . '/camera_left.asp');

	my $response = $self->{_ua}->request($request);

	my $settingsPage = $response->{_content};

	my $b_value;
	my $c_value;
	my $s_value;
	my $h_value;
	my $w_value;
	my $resolution;
	my $quality;
	my $framerate;
	my $frequency;
	my $autoexposure;

	if($settingsPage =~ /id="b_value" value="(\d+)"/im)
	{
		$b_value = $1;
	}
	if($settingsPage =~ /id="c_value" value="(\d+)"/im)
	{
		$c_value = $1;
	}
	if($settingsPage =~ /id="s_value" value="(\d+)"/im)
	{
		$s_value = $1;
	}
	if($settingsPage =~ /id="h_value" value="(\d+)"/im)
	{
		$h_value = $1;
	}
	if($settingsPage =~ /id="w_value" value="(\d+)"/im)
	{
		$w_value = $1;
	}
	if($settingsPage =~ /"(\d+)" selected>(\d+)X(\d+)/im)
	{
		$resolution = $1;
	}
	if($settingsPage =~ /"(\d+)" selected>(\s+)</im)
	{
		$quality = $1;
	}
	if($settingsPage =~ /"(\d+)" selected>(\d+)</im)
	{
		$framerate = $1;
	}
	if($settingsPage =~ /"(\d+)" selected>(50 Hz|60 Hz|Outdoor)</im)
	{
		$frequency = $1;
	}
	if($settingsPage =~ /NAME="autoexposure" checked value/im)
	{
		$autoexposure = "ON";
	}
	if($settingsPage =~ /NAME="autoexposure"  value/im)
	{
		$autoexposure = "OFF";
	}

	$self->imageSettingsBrightness($b_value);
	$self->imageSettingsContrast($c_value);
	$self->imageSettingsSaturation($s_value);
	$self->imageSettingsHue($h_value);
	$self->imageSettingsWhiteness($w_value);
	$self->imageSettingsResolution($resolution);
	$self->imageSettingsQuality($quality);
	$self->imageSettingsFrameRate($framerate);
	$self->imageSettingsFrequency($frequency);
	$self->imageSettingsAutoExp($autoexposure);

}

1;
__END__

=head1 NAME

Edimax - Perl extension for managing Edimax IC1500-series network cameras

=head1 SYNOPSIS

  use Net::Camera::Edimax::IC1500;
  my $camera = Net::Camera::Edimax::IC1500->new(
    hostname => 'camera.example.com',
    port => '80',
    username => 'admin',
    password => '1234',
  );
  $camera->getImageSettings();
  $camera->imageSettingsResolution(1);
  $camera->setImageSettings();

=head1 DESCRIPTION

The Edimax IC1500-series network cameras are managed via a web interface.
This module provides methods to control various aspects of the camera's
operation.

This module also supports the wireless version (the IC1500Wg), as the interface
is essentially identical (insofar as this module was developed using the Wg model)

=head1 METHODS

=over 4

=item new( hostname => $hostname, port => $port, username => $username, password => $password )

Creates a new Net::Camera::Edimax::IC1500 object.

  my $camera = Net::Camera::Edimax::IC1500->new(
    hostname => 'camera.example.com',
    port => '80',
    username => 'admin',
    password => '1234',
  );

=item getImageSettings

Gets the current image settings from the camera. This needs to be called before changing any image settings

=item setImageSettings

Activates the requested image settings.

=item getSystemSettings

Gets the current system settings. These are currently read-only, so there is no corresponding setSystemSettings.

=item getStatus

Gets the current status. These are read-only.

=item getLog

Gets the current entries in the logfile.

=item getSnapshot

Retrieves a snapshot from the device. The JPEG data is returned directly from this function.

=item imageSettingsResolution
=item imageSettingsResolution( 0|1|2 )

Gets/sets the image resolution. 0 is 640x480, 1 is 320x240 and 2 is 176x144.

=item imageSettingsQuality
=item imageSettingsQuality( 3|6|9|12|15 )

Gets/sets the image quality. 3, 6, 9, 12 and 15 refer to 'Highest', 'High', 'Normal', 'Low' and 'Lowest' respectively.

=item imageSettingsFrameRate
=item imageSettingsFrameRate( 1|3|5|10|15|20|25|30 )

Gets/sets the maximum frame rate for the MJPEG stream.

=item imageSettingsFrequency
=item imageSettingsFrequency( 60|50|0 )

Gets/sets the image frequency. '60' is 60Hz, '50' is 50Hz, and '0' is the 'Outdoor' setting.

=item imageSettingsBrightness
=item imageSettingsBrightness( 0-99 )

Gets/sets the image brightness. Value is an integer between 0 (lowest) and 99 (highest).

=item imageSettingsContrast
=item imageSettingsContrast( 0-99 )

Gets/sets the image contrast. Value is an integer between 0 (lowest) and 99 (highest).

=item imageSettingsSaturation
=item imageSettingsSaturation( 0-99 )

Gets/sets the image saturation. Value is an integer between 0 (lowest) and 99 (highest).

=item imageSettingsHue
=item imageSettingsHue( 0-99 )

Gets/sets the image hue. Value is an integer between 0 (lowest) and 99 (highest).

=item imageSettingsWhiteness
=item imageSettingsWhiteness( 0-30 )

Gets/sets the image hue. Value is an integer between 0 (lowest) and 30 (highest).

=item imageSettingsAutoExp
=item imageSettingsAutoExp( 'ON' )

Sets the image auto exposure. Pass it 'ON' to turn it on, and (predictably) 'OFF' to turn it off.

=item statusFirmware

Returns the firmware version running on the camera.

=item statusUptime

Returns the camera's uptime.

=item statusTime

Returns the device's date and time.

=item statusIPAddress

Returns the device's IP address.

=item statusNetmask

Returns the device's netmask.

=item statusGateway

Returns the device's default gateway.

=item statusDNSServer

Returns the device's DNS server.

=item statusMACAddress

Returns the device's MAC address.

=item statusVideoPort

Returns the TCP port used by the video streaming applet.

=item statusHTTPPort

Returns the TCP port used for the web front end.

=item systemSettingsCameraName

Returns the device's name.

=item systemSettingsPassword

Returns the device's password.

=item systemSettingsLED

Returns the LED visiblity status.

=item cycleSystemLED

Turns on/off the LEDs on the front of the device.

=item reboot()

Reboots the device.

=back

=head1 SEE ALSO

http://meh.org.uk/perl/Net-Camera-Edimax-IC1500/

=head1 AUTHOR

Andy Smith, E<lt>ams@meh.org.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008, 2009 by Andy Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
