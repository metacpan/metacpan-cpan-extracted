package Power::Outlet::Shelly;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::HTTP::JSON};

our $VERSION = '0.48';

=head1 NAME

Power::Outlet::Shelly - Control and query a Shelly GIPO Relay with HTTP REST API

=head1 SYNOPSIS

  my $outlet = Power::Outlet::Shelly->new(host=>"shelly", index=>0);
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";
  print $outlet->switch, "\n";
  print $outlet->cycle, "\n";

=head1 DESCRIPTION

Power::Outlet::Shelly is a package for controlling and querying a relay index on Shelly hardware.

From: L<https://shelly-api-docs.shelly.cloud/>

Commands can be executed via web (HTTP) requests, for example:

  http://<ip>/relay/0?turn=on
  http://<ip>/relay/0?turn=off
  http://<ip>/relay/0?turn=toggle
  http://<ip>/relay/0?timer=5

=head1 USAGE

  use Power::Outlet::Shelly;
  my $outlet = Power::Outlet::Shelly->new(host=>"sw-kitchen", style=>"relay", index=>0);
  print $outlet->on, "\n";

Command Line

  $ power-outlet Shelly ON host sw-kitchen style relay index 0

Command Line (from settings)

  $ cat /etc/power-outlet.ini

  [Kitchen]
  type=Shelly
  name=Kitchen
  host=sw-kitchen
  style=relay
  index=0
  groups=Inside Lights
  groups=Main Floor


  $ power-outlet Config ON section Kitchen
  $ curl http://127.0.0.1/cgi-bin/power-outlet-json.cgi?name=Kitchen;action=ON

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"Shelly", host=>"shelly", index=>0);
  my $outlet = Power::Outlet::Shelly->new(host=>"shelly", index=>0);

=head1 PROPERTIES

=head2 style

Set the style to support "relay" (1, 1L, 2.5, 4, Plug, Uni, EM, 3EM), "light" (Dimmer, Bulb, Vintage, Duo), "color" (RGB Color), or "white" (RGB White)

  my $style = $outlet->style;
  my $style = $outlet->style('light');

default: relay

=cut

sub style {
  my $self         = shift;
  $self->{'style'} = shift if @_;
  $self->{'style'} = $self->_style_default unless defined $self->{'style'};
  return $self->{'style'};
}

sub _style_default {'relay'};

=head2 index

Shelly hardware supports zero or more relay indexes starting at 0.

Default: 0

=cut

sub index {
  my $self         = shift;
  $self->{'index'} = shift if @_;
  $self->{'index'} = $self->_index_default unless defined $self->{'index'};
  return $self->{'index'};
}

sub _index_default {0};

=head2 host

Sets and returns the hostname or IP address.

Default: shelly

=cut

sub _host_default {'shelly'};

=head2 port

Sets and returns the port number.

Default: 80

=cut

sub _port_default {'80'};

#override Power::Outlet::Common::IP->_port_default

=head1 METHODS

=head2 name

=cut

#GET /settings/relay/{index} -> $return->{'name'}

sub _name_default {
  my $self = shift;
  return $self->_call('/settings')->{'name'};
}

=head2 query

Sends an HTTP message to the device to query the current state

=cut

sub query {
  my $self = shift;
  return $self->_call('')->{'ison'} ? 'ON' : 'OFF';
}

=head2 on

Sends a message to the device to Turn Power ON

=cut

sub on {
  my $self = shift;
  return $self->_call('', turn => 'on')->{'ison'} ? 'ON' : 'OFF';
}

=head2 off

Sends a message to the device to Turn Power OFF

=cut

sub off {
  my $self = shift;
  return $self->_call('', turn => 'off')->{'ison'} ? 'ON' : 'OFF';
}

=head2 switch

Sends a message to the device to toggle the power

=cut

#override Power::Outlet::Common->switch

sub switch {
  my $self = shift;
  return $self->_call('', turn => 'toggle')->{'ison'} ? 'ON' : 'OFF';
}

=head2 cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

=cut

#override Power::Outlet::Common->cycle

sub cycle {
  my $self = shift;
  my $cycle_duration = $self->cycle_duration; #from Power::Outlet::Common
  my $hash = $self->_call('', timer => $cycle_duration);
  return $hash->{'timer_started'} > 0 ? 'CYCLE' #is this the correct logic?
       : $hash->{'ison'}              ? 'ON'
       : 'OFF';
}

=head2 cycle_duration

Default; 10 seconds (floating point number)

=cut

sub _call {
  my $self      = shift;
  my $settings  = shift;
  my %param     = @_;
  #http://<ip>/settings/relay/0
  #http://<ip>/relay/0?turn=on
  #http://<ip>/relay/0?timer=10
  $self->http_path(sprintf('%s/%s/%s', $settings, $self->style, $self->index));
  my $url       = $self->url(undef); #isa URI from Power::Outlet::Common::IP::HTTP
  $url->query_form(%param);
  my $hash      = $self->json_request(GET => $url); #isa HASH

  die('Error: Method _call failed to return expected JSON format') unless ref($hash) eq 'HASH';
  return $hash;
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

L<https://shelly-api-docs.shelly.cloud/>

=cut

1;
