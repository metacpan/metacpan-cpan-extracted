package Power::Outlet;
use strict;
use warnings;

our $VERSION = '0.50';

=head1 NAME

Power::Outlet - Control and query network attached power outlets

=head1 SYNOPSIS

Command Line

  power-outlet Config    ON section "My Section"
  power-outlet iBoot     ON host mylamp
  power-outlet Hue       ON host mybridge id 1 username myuser
  power-outlet Shelly    ON host myshelly
  power-outlet SonoffDiy ON host mysonoff
  power-outlet Tasmota   ON host mytasmota
  power-outlet WeMo      ON host mywemo

Perl Object API

  my $outlet=Power::Outlet->new(                   #sane defaults from manufactures spec
                                type => "iBoot",
                                host => "mylamp",
                               );
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet is a package for controlling and querying network attached power outlets.  Individual hardware drivers in this name space must provide a common object interface for the controlling and querying of an outlet.  Common methods that every network attached power outlet must know are on, off, query, switch and cycle.  Optional methods might be implemented in some drivers like amps and volts.

=head2 SCOPE

The current scope of these packages is network attached power outlets. I started with iBoot and iBootBar since I had the hardware.  Hardware configuration is beyond the scope of this group of packages as most power outlets have functional web based or command line configuration tools.

=head2 Home Assistant

Integration with Home Assistant L<https://home-assistant.io/> can be accomplished by configuring a Command Line Switch. 

  switch:
    - platform: command_line
      switches:
        ibootbar_1:
          command_on: /usr/bin/power-outlet iBootBar ON host mybar.local outlet 1
          command_off: /usr/bin/power-outlet iBootBar OFF host mybar.local outlet 1
          command_state: /usr/bin/power-outlet iBootBar QUERY host mybar.local outlet 1 | /bin/grep -q ON
          friendly_name: My iBootBar Outlet 1

See L<https://home-assistant.io/components/switch.command_line/>

=head2 Node Red

Integration with Node Red L<https://nodered.org/> can be accomplished with the included JSON web API power-outlet-json.cgi.  The power-outlet-json.cgi script is a layer on top of L<Power::Outlet::Config> where the "name" parameter maps to the section in the /etc/power-outlet.ini INI file.

To access all of these devices use an http request node with a URL https://127.0.0.1/cgi-bin/power-outlet-json.cgi?name={{topic}};action={{payload}} then simply set the topic to the INI section and the action to either ON or OFF.

=head1 USAGE

The Perl one liner

  perl -MPower::Outlet -e 'print Power::Outlet->new(type=>"Tasmota", host=>shift)->switch, "\n"' myhost

The included command line script

  power-outlet Shelly ON host myshelly

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"WeMo",     host=>"mywemo");

=cut

sub new {
  my $this   = shift;
  my $base   = ref($this) || $this;
  my %data   = @_;
  my $type   = $data{"type"} or die("Error: the type parameter is required.");
  my $class  = join("::", $base, $type);
  local $@;
  eval "use $class";
  my $error  = $@;
  die(qq{Errot: Cannot find package "$class" for outlet type "$type"\n}) if $error;
  my $outlet = $class->new(%data);
  return $outlet;
}

=head1 BUGS

Please open an issue on github

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Power::Outlet::iBoot>, L<Power::Outlet::iBootBar>, L<Power::Outlet::WeMo>, L<Power::Outlet::Hue>

=cut

1;
