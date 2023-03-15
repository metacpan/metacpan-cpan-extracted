package Power::Outlet::TuyaAPI;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP};
use WebService::Tuya::IoT::API 0.02; #device_information

our $VERSION = '0.48';

=head1 NAME

Power::Outlet::TuyaAPI - Control and query an outlet via the TuyaAPI.

=head1 SYNOPSIS

  my $outlet = Power::Outlet::TuyaAPI->new(client_id=>"abc123", client_secret=>"cde234", deviceid=>"def345", switch=>"switch_1");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::TuyaAPI is a package for controlling and querying an outlet via the TuyaAPI.

This package is a wrapper around L<WebService::Tuya::IoT::API> please see that documentation for device configuration.

=head1 USAGE

  use Power::Outlet::TuyaAPI;
  my $relay = Power::Outlet::TuyaAPI->new(client_id=>"abc123", client_secret=>"cde234", deviceid=>"def345", switch=>"switch_1");
  print $relay->on, "\n";

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"TuyaAPI", client_id=>"abc123", client_secret=>"cde234", deviceid=>"def345", switch=>"switch_1");
  my $outlet = Power::Outlet::TuyaAPI->new(client_id=>"abc123", client_secret=>"cde234", deviceid=>"def345", switch=>"switch_1");

=head1 PROPERTIES

=head2 host 

default: openapi.tuyaus.com

=cut

sub _host_default {undef}; #maps to America data center in WebService::Tuya::IoT::API
sub _port_default {"443"}; #not used but 443 is right

=head2 client_id

The Client ID found on https://iot.tuya.com/ project overview page.

=cut

sub client_id {
  my $self             = shift;
  $self->{'client_id'} = shift if @_;
  $self->{'client_id'} = $self->_client_id_default unless defined $self->{'client_id'};
  die('Error: client_id required') unless defined $self->{'client_id'};
  return $self->{'client_id'};
}

sub _client_id_default {undef};

=head2 client_secret

The Client Secret found on https://iot.tuya.com/ project overview page.

=cut

sub client_secret {
  my $self                 = shift;
  $self->{'client_secret'} = shift if @_;
  $self->{'client_secret'} = $self->_client_secret_default unless defined $self->{'client_secret'};
  die('Error: client_secret required') unless defined $self->{'client_secret'};
  return $self->{'client_secret'};
}

sub _client_secret_default {undef};

=head2 deviceid

The Device ID found on https://iot.tuya.com/ project devices page.

=cut

sub deviceid {
  my $self            = shift;
  $self->{'deviceid'} = shift if @_;
  $self->{'deviceid'} = $self->_deviceid_default unless defined $self->{'deviceid'};
  die('Error: deviceid required') unless defined $self->{'deviceid'};
  return $self->{'deviceid'};
}

sub _deviceid_default {undef};

=head2 relay

The relay name or "code" for a particular relay on the device.  Devices with a single relay this value will most likely be switch_1 but, for devices with multiple relays the first relay is normally switch_1 and subsequent relays should be labeled switch_2, etc.

default: switch_1

=cut

sub relay {
  my $self        = shift;
  $self->{'relay'} = shift if @_;
  $self->{'relay'} = $self->_relay_default unless defined $self->{'relay'};
  return $self->{'relay'};
}

sub _relay_default {'switch_1'};

=head1 METHODS

=head2 name

Returns the name from the device information API

Note: The name is cached for the life of the object.

=cut

sub name {
  my $self = shift;
  unless (exists $self->{'name'}) {
    my $response    = $self->_WebService_Tuya_IoT_API->device_information($self->deviceid);
    $self->{'name'} = $response->{'result'}->{'name'};
  }
  return $self->{'name'};
}

=head2 query

Sends an HTTP message to the API to query the current state of the device relay

=cut

sub query {
  my $self  = shift;
  my $value = $self->_WebService_Tuya_IoT_API->device_status_code_value($self->deviceid, $self->relay); #isa JSON Boolean
  return $value ? 'ON' : 'OFF';
}

=head2 on

Sends a message to the API to turn the device relay ON

=cut

sub on {
  my $self          = shift;
  my $state_boolean = \1; #JSON true
  my $response      = $self->_WebService_Tuya_IoT_API->device_command_code_value($self->deviceid, $self->relay, $state_boolean);
  return $response->{'success'} ? 'ON' : '';
}

=head2 off

Sends a message to the API to turn the device relay OFF

=cut

sub off {
  my $self          = shift;
  my $state_boolean = \0; #JSON false
  my $response      = $self->_WebService_Tuya_IoT_API->device_command_code_value($self->deviceid, $self->relay, $state_boolean);
  return $response->{'success'} ? 'OFF' : '';
}

=head2 switch

Sends a message to the API to toggle the device relay state

=cut

#see Power::Outlet::Common->switch

=head2 cycle

Sends messages to the device to cycle the device relay state

=cut

#see Power::Outlet::Common->cycle
# Note: switch in 10 seconds: $self->_WebService_Tuya_IoT_API->device_commands($self->deviceid, {code=>'countdown_1', value=>$self->cycle_duration}); 

sub _WebService_Tuya_IoT_API {
  my $self = shift;
  unless ($self->{'_WebService_Tuya_IoT_API'}) {
    my $client_id     = $self->client_id      or die("Error: client_id required");
    my $client_secret = $self->client_secret or die("Error: client_secret required");
    $self->{'_WebService_Tuya_IoT_API'} = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret, http_hostname=>$self->host);
  }
  return $self->{'_WebService_Tuya_IoT_API'};
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

L<https://tasmota.github.io/docs/#/Commands>

=cut

1;
