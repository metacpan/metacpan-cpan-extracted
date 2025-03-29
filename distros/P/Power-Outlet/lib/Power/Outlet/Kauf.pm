package Power::Outlet::Kauf;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::HTTP::JSON};

our $VERSION = '0.51';

=head1 NAME

Power::Outlet::Kauf - Control and query a Kauf Plug with HTTP REST API

=head1 SYNOPSIS

  my $outlet = Power::Outlet::Kauf->new(host=>"my_kauf_plug");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";
  print $outlet->switch, "\n";
  print $outlet->cycle, "\n";

=head1 DESCRIPTION

Power::Outlet::Kauf is a package for controlling and querying a Kauf Plug.

From: L<https://github.com/KaufHA/common/> and L<https://github.com/hightowe/control_outdoor_lighting-pl>

Commands can be executed via web (HTTP) requests, for example:

  POST http://10.10.10.39/switch/kauf_plug/turn_off  => status 200
  POST http://10.10.10.39/switch/kauf_plug/turn_on   => status 200
  GET  http://10.10.10.39/switch/kauf_plug           => {"id":"plug name","value":true,"state":"ON"}

=head1 USAGE

  use Power::Outlet::Kauf;
  my $outlet = Power::Outlet::Kauf->new(host=>"sw-kitchen");
  print $outlet->on, "\n";

Command Line

  $ power-outlet Kauf ON host sw-kitchen

Command Line (from settings)

  $ cat /etc/power-outlet.ini

  [Kitchen]
  type=Kauf
  name=Kitchen
  host=sw-kitchen
  groups=Inside Lights
  groups=Main Floor

  $ power-outlet Config ON section Kitchen
  $ curl http://127.0.0.1/cgi-bin/power-outlet-json.cgi?name=Kitchen;action=ON

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"Kauf", host=>"my_kauf_plug");
  my $outlet = Power::Outlet::Kauf->new(host=>"my_kauf_plug");

=head1 PROPERTIES

=head2 host

Sets and returns the hostname or IP address.

=head2 port

Sets and returns the port number.

Default: 80

=cut

sub _port_default {'80'};

#override Power::Outlet::Common::IP->_port_default

=head1 METHODS

=head2 name

=cut

#from Power::Outlet::Common

sub _name_default {
  my $self = shift;
  return $self->_call(GET => '/switch/kauf_plug')->{'id'};
}

=head2 query

Sends an HTTP message to the device to query the current state

=cut

sub query {
  my $self = shift;
  return $self->_call(GET => '/switch/kauf_plug')->{'state'}; #ON|OFF
}

=head2 on

Sends a message to the device to Turn Power ON

=cut

sub on {
  my $self = shift;
  return $self->_call(POST => '/switch/kauf_plug/turn_on', 'ON');
}

=head2 off

Sends a message to the device to Turn Power OFF

=cut

sub off {
  my $self = shift;
  return $self->_call(POST => '/switch/kauf_plug/turn_off', 'OFF');
}

=head2 switch

Sends a message to the device to toggle the power

=cut

#from Power::Outlet::Common->switch

=head2 cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

=cut

#from Power::Outlet::Common->cycle

=head2 cycle_duration

Default; 10 seconds (floating point number)

=cut

sub _call {
  my $self          = shift;
  my $method        = shift; #POST returns ON|OFF, GET returns {}
  my $path          = shift; #e.g., /switch/kauf_plug/turn_on
  my $state_success = shift; #ON|OFF - Only used for GET requests
  $self->http_path($path);   #from Power::Outlet::Common::IP::HTTP
  my $url           = $self->url(undef); #isa URI from Power::Outlet::Common::IP::HTTP
  if ($method eq 'GET') {       #get status/state
    my $hash     = $self->json_request($method, $url); #isa HASH
    die('Error: Method _call failed to return expected JSON format') unless ref($hash) eq 'HASH';
    return $hash;
  } elsif ($method eq 'POST') { #set state
    my $response = $self->http_client->request($method, $url);
    return $response->{"status"} eq  '200' ? $state_success : 'Unknown';
  } else {
    die("Error: Invalid HTTP Method. Expected GET or POST");
  }
}

=head1 COPYRIGHT & LICENSE

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;
