package Power::Outlet::OpenBeken;
use strict;
use warnings;
use base qw{Power::Outlet::Tasmota};

#See Power::Outlet::Tasmota for code but use OpenBeken in case we need to tweak any operations for OpenBeken in the future.

our $VERSION = '0.52';

=head1 NAME

Power::Outlet::OpenBeken - Control and query an OpenBeken configured device

=head1 SYNOPSIS

  my $outlet = Power::Outlet::OpenBeken->new(host => "myhost", relay => "POWER1");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::OpenBeken is a package for controlling and querying OpenBeken flashed hardware over the exposed HTTP interface. OpenBeken supports multiple chipsets, including ESWIN, Transa Semi, Lightning Semi, Espressif, Beken, WinnerMicro, Xradiotech/Allwinner, Realtek, and Bouffalo Lab.

The OpenBeken project adopted the HTTP command interface from the Tasmota project as defined at L<https://tasmota.github.io/docs/#/Commands>

Commands can be executed via web (HTTP) requests, for example:

  http://<ip>/cm?cmnd=Power%20TOGGLE
  http://<ip>/cm?cmnd=Power%20On
  http://<ip>/cm?cmnd=Power%20off
  http://<ip>/cm?user=foo&password=bar&cmnd=Power%20Toggle

Examples:

Query default relay

  $ curl http://myhost/cm?cmnd=POWER1
  {"POWER1":"ON"}

Toggle (Switch) relay 4

  $ curl http://myhost/cm?user=foo;password=bar;cmnd=POWER4+TOGGLE
  {"POWER4":"OFF"}

Turn ON relay 2

  $ curl http://myhost/cm?user=foo;password=bar;cmnd=POWER2+ON
  {"POWER2":"ON"}

=head1 USAGE

  use Power::Outlet::OpenBeken;
  my $relay = Power::Outlet::OpenBeken->new(host=>"myhost", relay=>"POWER1");
  print $relay->on, "\n";

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"OpenBeken", host=>"myhost", relay=>"POWER2");
  my $outlet = Power::Outlet::OpenBeken->new(host=>"myhost", relay=>"POWER2");

=head1 PROPERTIES

=head2 relay

Relays map to the relay tokens "POWER1", "POWER2", ... "POWER8". With "POWER" being the default relay name for the first relay defined in the configuration.

Default: POWER1

=head2 host

Sets and returns the hostname or IP address.

Default: openbeken

=cut

sub _host_default {'openbeken'};

=head2 port

Sets and returns the port number.

Default: 80

=head2 http_path

Sets and returns the http_path.

Default: /cm

=head2 user

Sets and returns the user used for authentication with the OpenBeken hardware

  my $outlet = Power::Outlet::OpenBeken->new(host=>"myhost", relay=>"POWER1", user=>"mylogin", password=>"mypassword");
  print $outlet->query, "\n";

Default: undef() #which is only passed on the url when defined

=head2 password

Sets and returns the password used for authentication with the OpenBeken hardware

Default: "" #which is only passed on the url when user property is defined

=head1 METHODS

=head2 name

Returns the FriendlyName from the OpenBeken hardware.

Note: The FriendlyName is cached for the life of the object.

=head2 query

Sends an HTTP message to the device to query the current state

=head2 on

Sends a message to the device to Turn Power ON

=head2 off

Sends a message to the device to Turn Power OFF

=head2 switch

Sends a message to the device to toggle the power

=head2 cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

=cut

#see Power::Outlet::Common->cycle

=head1 BUGS and SUPPORT

Please use GitHub

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT

=head1 COPYRIGHT

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<https://github.com/openshwprojects/OpenBK7231T_App>
L<https://tasmota.github.io/docs/#/Commands>

=cut

1;
