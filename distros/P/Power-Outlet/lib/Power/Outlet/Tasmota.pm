package Power::Outlet::Tasmota;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::HTTP::JSON};

our $VERSION='0.22';

=head1 NAME

Power::Outlet::Tasmota - Control and query a Tasmota GIPO configured as a Relay (Switch or Button)

=head1 SYNOPSIS

  my $outlet = Power::Outlet::Tasmota->new(host => "tasmota", relay => "POWER");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::Tasmota is a package for controlling and querying a relay on Tasmota ESP8266 hardware.

From: L<https://tasmota.github.io/docs/#/Commands>

Commands can be executed via web (HTTP) requests, for example:

  http://<ip>/cm?cmnd=Power%20TOGGLE
  http://<ip>/cm?cmnd=Power%20On
  http://<ip>/cm?cmnd=Power%20off
  http://<ip>/cm?user=admin&password=joker&cmnd=Power%20Toggle

Example: 


Query default relay

  $ curl http://tasmota/cm?cmnd=POWER
  {"POWER1":"ON"}

Toggle (Switch) relay 4

  $ curl http://tasmota/cm?user=foo;password=bar;cmnd=POWER4+TOGGLE
  {"POWER4":"OFF"}

Turn ON relay 2

  $ curl http://tasmota/cm?user=foo;password=bar;cmnd=POWER2+ON
  {"POWER2":"ON"}

=head1 USAGE

  use Power::Outlet::Tasmota;
  my $relay = Power::Outlet::Tasmota->new(host=>"tasmota", relay=>"POWER2");
  print $relay->on, "\n";

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"Tasmota", host=>"tasmota", relay=>"POWER2");
  my $outlet = Power::Outlet::Tasmota->new(host=>"tasmota", relay=>"POWER2");

=head1 PROPERTIES

=head2 relay

Tasmota version 8.1.0 supports up to 8 relays.  These 8 relays map to the relay tokens "POWER1", "POWER2", ... "POWER8". With "POWER" being the default relay name for the first relay defined in the configuration.

Default: POWER

=cut

sub relay {
  my $self         = shift;
  $self->{'relay'} = shift if @_;
  $self->{'relay'} = $self->_relay_default unless defined $self->{'relay'};
  return $self->{'relay'};
}

sub _relay_default {'POWER'};

=head2 host

Sets and returns the hostname or IP address.

Default: tasmota

=cut

sub _host_default {'tasmota'};

=head2 port

Sets and returns the port number.

Default: 80

=cut

sub _port_default {'80'};

=head2 http_path

Sets and returns the http_path.

Default: /cm

=cut

sub _http_path_default {'/cm'};


=head2 user

Sets and returns the user used for authentication with the Tasmota hardware

  my $outlet = Power::Outlet::Tasmota->new(host=>"tasmota", relay=>"POWER", user=>"mylogin", password=>"mypassword");
  print $outlet->query, "\n";

Default: undef() #which is only passed on the url when defined

=cut

sub user {
  my $self        = shift;
  $self->{'user'} = shift if @_;
  $self->{'user'} = $self->_user_default unless defined $self->{'user'};
  return $self->{'user'};
}

sub _user_default {undef};

=head2 password

Sets and returns the password used for authentication with the Tasmota hardware

Default: "" #which is only passed on the url when user property is defined

=cut

sub password {
  my $self            = shift;
  $self->{'password'} = shift if @_;
  $self->{'password'} = $self->_password_default unless defined $self->{'password'};
  return $self->{'password'};
}

sub _password_default {''};


=head1 METHODS

=head2 name

=cut

sub name {
  my $self = shift;
  unless ($self->{'name'}) {
    my $fn = $self->relay;
    $fn =~ s/POWER/FriendlyName/i;             # e.g. POWER2 => FriendlyName2
    $self->{'name'} = $self->_call($fn => ''); # {"FriendlyName4":"Smart Outlet Bottom Amber LED"}
  }
  return $self->{'name'};
}

=head2 query

Sends an HTTP message to the device to query the current state

=cut

sub query {
  my $self = shift;
  return $self->_call($self->relay, '');
}

=head2 on

Sends a message to the device to Turn Power ON

=cut

sub on {
  my $self = shift;
  return $self->_call($self->relay, 'ON');
}

=head2 off

Sends a message to the device to Turn Power OFF

=cut

sub off {
  my $self = shift;
  return $self->_call($self->relay, 'OFF');
}

=head2 switch

Sends a message to the device to toggle the power

=cut

sub switch {
  my $self = shift;
  return $self->_call($self->relay, 'TOGGLE');
}

=head2 cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

=cut

#see Power::Outlet::Common->cycle

sub _call {
  my $self     = shift;
  my $command  = shift; #e.g. POWER1 or FriendlyName2
  my $argument = shift;
  die('Error: Method _call() syntax _call(POWERx => ""|ON|OFF|TOGGLE)') unless $command  =~ m/\A(POWER|FriendlyName)[1-9]?\Z/i;
  die('Error: Method _call() syntax _call(""|ON|OFF|TOGGLE)')           unless $argument =~ m/\A(|ON|OFF|TOGGLE)\Z/i;

  #http://<ip>/cm?user=admin&password=joker&cmnd=Power%20Toggle
  my $url      = $self->url; #isa URI from Power::Outlet::Common::IP::HTTP
  my @auth     = $self->user ? (user => $self->user, password => $self->password) : ();
  my $cmnd     = $argument   ? join(" ", $command => $argument)                   : $command;
  $url->query_form(@auth, cmnd => $cmnd);
  #print "$url\n";

  my $hash     = $self->json_request(GET => $url); #isa HASH
  #{"POWER1":"OFF"}
  #{"Command":"Unknown"}
  #{"WARNING":"Enter command cmnd="}

  die("Error: Method _call($argument) failed to return expected JSON format") unless ref($hash) eq "HASH";
  my ($key)    = keys %$hash;
  my $value    = $hash->{$key}; #ON|OFF or error
  if ($key =~ m/\APOWER[1-9]\Z/i) {
    die(qq{Error: Web service error, Value "$value" not ON or OFF}) unless $value =~ m/\A(ON|OFF)\Z/i;
  } elsif ($key =~ m/\AFriendlyName[1-9]\Z/i) {
    #ok
  } else {
    die(qq{Error: Web service error, $key: "$value"});
  }
  return $value;
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
