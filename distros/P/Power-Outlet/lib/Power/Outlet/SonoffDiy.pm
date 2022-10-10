package Power::Outlet::SonoffDiy;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::HTTP::JSON};
use JSON qw{decode_json};

our $VERSION = '0.46';

=head1 NAME

Power::Outlet::SonoffDiy - Control and query a Sonoff DIY device

=head1 SYNOPSIS

  my $outlet = Power::Outlet::SonoffDiy->new(host => "SonoffDiy");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::SonoffDiy is a package for controlling and querying Sonoff ESP8266 hardware running Sonoff firmware in DIY mode.  This package supports and has been tested on both the version 1.4 (firmware 3.3.0) and version 2.0 (firmware 3.6.0) of the API.

From: L<https://github.com/itead/Sonoff_Devices_DIY_Tools>

Commands can be executed via HTTP POST requests, for example:

  curl -i -XPOST -d '{"deviceid":"","data":{}}' http://10.10.7.1:8081/zeroconf/info

1.4 Return where data is a string

  {
    "seq"   : 21,
    "error" : 0,
    "data"  : "{\"switch\":\"off\",\"startup\":\"stay\",\"pulse\":\"off\",\"pulseWidth\":500,\"ssid\":\"my_ssid\",\"otaUnlock\":false}"
  }

2.0 Return where data is an object

  {
    "seq"   : 12,
    "error" : 0,
    "data":{
      "switch"         : "on",
      "startup"        : "stay",
      "pulse"          : "off",
      "pulseWidth"     : 500,
      "ssid"           : "my_ssid",
      "otaUnlock"      : false,
      "fwVersion"      : "3.6.0",
      "deviceid"       : "1001262ec1",
      "bssid"          : "fc:ec:da:81:c:98",
      "signalStrength" : -61
    }
  }

  curl -i -XPOST -d '{"deviceid":"","data":{"switch":"off"}}' http://10.10.7.1:8081/zeroconf/switch
  {
   "seq"   : 22,
   "error" : 0
  }

  curl -i -XPOST -d '{"deviceid":"","data":{"switch":"on"}}' http://10.10.7.1:8081/zeroconf/switch
  {
   "seq"   : 23,
   "error" : 0
  }

=head1 USAGE

  use Power::Outlet::SonoffDiy;
  my $outlet = Power::Outlet::SonoffDiy->new(host=>"SonoffDiy");
  print $outlet->on, "\n";

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"SonoffDiy", host=>"SonoffDiy");
  my $outlet = Power::Outlet::SonoffDiy->new(host=>"SonoffDiy");

=head1 PROPERTIES

=head2 host

Sets and returns the hostname or IP address.

Default: SonoffDiy

=cut

sub _host_default {'SonoffDiy'};

=head2 port

Sets and returns the port number.

Default: 8081

=cut

sub _port_default {'8081'};

=head2 http_path

Sets and returns the http_path.

Default: /

=cut

sub _http_path_default {'/'};

=head1 METHODS

=head2 name

Returns the name as configured.

Note: The Sonoff DIY firmware does not support setting a hostname or friendly name.

=cut

#see Power::Outlet::Common->name
#see Power::Outlet::Common::IP->_name_default

=head2 query

Sends an HTTP message to the device to query the current state

=cut

sub query {
  my $self = shift;
  return $self->_call();
}

=head2 on

Sends a message to the device to Turn Power ON

=cut

sub on {
  my $self = shift;
  return $self->_call('ON');
}

=head2 off

Sends a message to the device to Turn Power OFF

=cut

sub off {
  my $self = shift;
  return $self->_call('OFF');
}

=head2 switch

Sends a message to the device to toggle the power

=cut

#see Power::Outlet::Common->switch

=head2 cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

=cut

#see Power::Outlet::Common->cycle

#from https://github.com/itead/Sonoff_Devices_DIY_Tools/blob/master/SONOFF%20DIY%20MODE%20Protocol%20Doc%20v1.4.md

our %ERROR_STRING = (
                     '0'   => 'successfully',
                     '400' => 'The operation failed and the request was formatted incorrectly. The request body is not a valid JSON format.',
                     '401' => 'The operation failed and the request was unauthorized. Device information encryption is enabled on the device, but the request is not encrypted.',
                     '404' => 'The operation failed and the device does not exist. The device does not support the requested deviceid.',
                     '422' => 'The operation failed and the request parameters are invalid. For example, the device does not support setting specific device information.',
                     '403' => 'The operation failed and the OTA function was not unlocked. The interface "3.2.6OTA function unlocking" must be successfully called first.',
                     '408' => 'The operation failed and the pre-download firmware timed out. You can try to call this interface again after optimizing the network environment or increasing the network speed.',
                     '413' => 'The operation failed and the request body size is too large. The size of the new OTA firmware exceeds the firmware size limit allowed by the device.',
                     '424' => 'The operation failed and the firmware could not be downloaded. The URL address is unreachable (IP address is unreachable, HTTP protocol is unreachable, firmware does not exist, server does not support Range request header, etc.)',
                     '471' => "The operation failed and the firmware integrity check failed. The SHA256 checksum of the downloaded new firmware does not match the value of the request body's sha256sum field. Restarting the device will cause bricking issue.",
                    );

sub _call {
  my $self               = shift;
  my $switch             = shift || ''; #'' or 'ON' or 'OFF'
  die('Error: Method _call() syntax _call(""|ON|OFF)') unless $switch =~ m{\A(|ON|OFF)\Z};

  my $path               = $switch ? 'zeroconf/switch' : 'zeroconf/info';

  my $payload            = {};
  $payload->{'deviceid'} = '';                                   #required to exist for 1.4
  $payload->{'data'}     = $switch ? {switch=>lc($switch)} : {}; #required to exist

  #http://<ip>:8081/zeroconf/switch
  my $url  = $self->url; #isa URI from Power::Outlet::Common::IP::HTTP
  $url->path($path);
  #print "$url\n";

  my $hash     = $self->json_request(POST => $url, $payload); #isa HASH
  #{"seq":16,"error":0}
  #{"seq":17,"error":0,"data":"{\"switch\":\"on\",\"startup\":\"stay\",\"pulse\":\"off\",\"pulseWidth\":500,\"ssid\":\"davisnetworks.com\",\"otaUnlock\":false}"}
  die('Error: Method _call() web service did not return JSON object') unless ref($hash) eq 'HASH';
  my $error_code = $hash->{'error'};
  if ($error_code) {
    my $error_string = $ERROR_STRING{$error_code} || "Unknown Error Code $error_code";
    die(sprintf('Error: Method _call(), Web Service Error: %s "%s"', $error_code, $error_string));
  }

  unless ($switch) { #info
    my $data  = $hash->{'data'} or die('Error: JSON malformed missing data key');
    local $@;
    $data     = eval{decode_json($data)} unless ref($data) eq 'HASH'; #bug in 1.4 API fixed in 2.0
    my $error = $@;
    die(qq{Error: JSON malformed converting data JSON}) if $error;
    die(qq{Error: JSON malformed converting data JSON}) unless ref($data) eq 'HASH';
    $switch   = $data->{'switch'} or die('Error: JSON malformed extracting switch value');
    die(qq{Error: JSON malformed switch value unexpected "$switch"}) unless $switch =~ m{\A(on|off)\Z}i;
    $switch   = uc($switch); #match API
  }

  return $switch;
}

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com

=head1 COPYRIGHT

Copyright (c) 2020 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<https://github.com/itead/Sonoff_Devices_DIY_Tools>

=cut

1;
