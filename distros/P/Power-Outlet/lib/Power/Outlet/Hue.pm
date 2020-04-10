package Power::Outlet::Hue;
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use base qw{Power::Outlet::Common::IP::HTTP::JSON};

our $VERSION='0.24';

=head1 NAME

Power::Outlet::Hue - Control and query a Philips Hue light

=head1 SYNOPSIS

  my $outlet=Power::Outlet::Hue->new(host => "mybridge", id=>1, username=>"myuser");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::Hue is a package for controlling and querying a light on a Philips Hue network attached bridge.

=head1 USAGE

  use Power::Outlet::Hue;
  my $lamp=Power::Outlet::Hue->new(host=>"mybridge", id=>1, username=>"myuser");
  print $lamp->on, "\n";

=head1 CONSTRUCTOR

=head2 new

  my $outlet=Power::Outlet->new(type=>"Hue", host=>"mybridge", id=>1);
  my $outlet=Power::Outlet::Hue->new(host=>"mybridge", id=>1);

=head1 PROPERTIES

=head2 id

ID for the particular light as configured in the Philips Hue Bridge

Default: 1

=cut

sub id {
  my $self      = shift;
  $self->{"id"} = shift if @_;
  $self->{"id"} = $self->_id_default unless defined $self->{"id"};
  return $self->{"id"};
}

sub _id_default {1};

=head2 resource

Resource for the particular object as presented on the Philips Hue Bridge

Default: lights

Currently supported Resources from L<https://developers.meethue.com/documentation/core-concepts>

  lights    - resource which contains all the light resources
  groups    - resource which contains all the groups
  config    - resource which contains all the configuration items
  schedules - which contains all the schedules
  scenes    - which contains all the scenes
  sensors   - which contains all the sensors
  rules     - which contains all the rules

=cut

sub resource {
  my $self            = shift;
  $self->{"resource"} = shift if @_;
  $self->{"resource"} = $self->_resource_default unless defined $self->{"resource"};
  return $self->{"resource"};
}

sub _resource_default {'lights'};

=head2 host

Sets and returns the hostname or IP address.

Default: mybridge

=cut

sub _host_default {"mybridge"};

=head2 port

Sets and returns the port number.

Default: 80

=cut

sub _port_default {"80"};

=head2 username

Sets and returns the username used for authentication with the Hue Bridge

Default: newdeveloper (Hue Emulator default)

=cut

sub username {
  my $self            = shift;
  $self->{"username"} = shift if @_;
  $self->{"username"} = $self->_username_default unless defined $self->{"username"};
  return $self->{"username"};
}

sub _username_default {"newdeveloper"};

=head2 name

Returns the configured friendly name for the device

=cut

sub _name_default { #overloaded _name_default so the name will be cached for the life of this object
  my $self = shift;
  my $url  = $self->url; #isa URI from Power::Outlet::Common::IP::HTTP
  $url->path($self->_path);
  my $res  = $self->json_request(GET => $url); #isa perl structure
  return $res->{"name"}; #isa string
}

=head1 METHODS

=cut

#head2 _path

#Builds the URL path

#cut

sub _path {
  my $self     = shift;
  my $state    = shift;
  my @state    = defined($state)          ? ($state)          : ();
  my @resource = defined($self->resource) ? ($self->resource) : (); #support undef resource just in case needed
  return join('/', '', 'api', $self->username, @resource, $self->id, @state);
}

=head2 query

Sends an HTTP message to the device to query the current state

=cut

#Response: {"identifier":null,"state":{"on":true,"bri":254,"hue":4444,"sat":254,"xy":[0.0,0.0],"ct":0,"alert":"none","effect":"none","colormode":"hs","reachable":true,"transitionTime":null},"type":"Extended color light","name":"Hue Lamp 1","modelid":"LCT001","swversion":"65003148","pointsymbol":{"1":"none","2":"none","3":"none","4":"none","5":"none","6":"none","7":"none","8":"none"}}
#Response: [{"error":{"address":"/","description":"unauthorized user","type":"1"}}]
#Response: [{"error":{"address":"/lights/333","description":"resource, /lights/333, not available","type":"3"}}]


sub query {
  my $self = shift;
  if (defined wantarray) { #scalar and list context

    #url configuration
    my $url = $self->url; #isa URI from Power::Outlet::Common::IP::HTTP
    $url->path($self->_path);

    #web request
    my $res = $self->json_request(GET => $url); #isa perl structure

    #Response is an ARRAY on error and a HASH on success
    if (ref($res) eq "HASH") {
      die("Error: (query) state does not exists")              unless exists $res->{"state"};
      die("Error: (query) state is not a hash")                unless ref($res->{"state"}) eq "HASH";
      die("Error: (query) state does not provide on property") unless exists $res->{"state"}->{"on"};
      my $state = $res->{"state"}->{"on"}; #isa boolean true/false
      return $state ? "ON" : "OFF";
    } elsif (ref($res) eq "ARRAY") {
      my $hash  = shift(@$res);
      die(sprintf(qq{Error: (query) "%s"}, $hash->{"error"}->{"description"})) if exists $hash->{"error"};
      die(sprintf("Error: (query) Unkown Error: URL: %s\n\n%s", $url, Dumper($res)));
    } else {
      die(sprintf("Error: (query) Unkown Error: URL: %s\n\n%s", $url, Dumper($res)));
    }
  } else { #void context
    return;
  }
}

=head2 on

Sends a message to the device to Turn Power ON

=cut

#Response: [{"success":{"/lights/1/state/on":true}}]
#Response: [{"error":{"address":"/","description":"unauthorized user","type":"1"}}]
#Response: [{"error":{"address":"/lights/333","description":"resource, /lights/333, not available","type":"3"}}]

sub on {
  my $self = shift;
  return $self->_call("on");
}

=head2 off

Sends a message to the device to Turn Power OFF

=cut

sub off {
  my $self = shift;
  return $self->_call("off");
}

sub _call {
  my $self    = shift;
  my $input   = shift or die;
  my $boolean = $input eq "on"  ? \1 : #JSON true
                $input eq "off" ? \0 : #JSON false
                die("Error: (_call) syntax _call('on'||'off')");

  #url configuration
  my $url     = $self->url; #isa URI from Power::Outlet::Common::IP::HTTP
  $url->path($self->_path('state'));

  #web request
  my $array   = $self->json_request(PUT => $url, {on=>$boolean}); #isa perl structure

  #error handling
  die("Error: ($input) failed to return expected JSON format") unless ref($array) eq "ARRAY";
  my $hash    = shift(@$array);
  die("Error: ($input) Failed to return expected JSON format") unless ref($hash) eq "HASH";
  die(sprintf(qq{Error: ($input) "%s"}, $hash->{"error"}->{"description"})) if exists $hash->{"error"};
  die(sprintf("Error: ($input) Unkown Error: URL: %s\n\n%s", $url, Dumper($array))) unless exists $hash->{"success"};
  my $success = $hash->{"success"};
  #state normalization
  my $key     = sprintf("/lights/%s/state/on", $self->id);
  die("Error: ($input) Unkown success state") unless exists $success->{$key};
  my $state   = $success->{$key};
  return $state ? "ON" : "OFF";
}

=head2 switch

Queries the device for the current status and then requests the opposite.

=cut

#see Power::Outlet::Common->switch

=head2 cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

=cut

#see Power::Outlet::Common->cycle

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com

Thanks to Mathias Neerup manee12 at student.sdu.dk - L<https://rt.cpan.org/Ticket/Display.html?id=123965>

=head1 COPYRIGHT

Copyright (c) 2018 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<http://www.developers.meethue.com/philips-hue-api>, L<http://steveyo.github.io/Hue-Emulator/>, L<https://home-assistant.io/components/emulated_hue/>

=cut

1;
