package Power::Outlet;
use strict;
use warnings;

our $VERSION='0.42';

=head1 NAME

Power::Outlet - Control and query network attached power outlets

=head1 SYNOPSIS

Command Line

  power-outlet iBoot    ON   host mylamp
  power-outlet iBoot    OFF  host mylamp
  power-outlet iBootBar ON   host mybar   outlet 1
  power-outlet iBootBar OFF  host mybar   outlet 1
  power-outlet WeMo     ON   host mywemo
  power-outlet WeMo     OFF  host mywemo

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

The current scope of these packages is network attached power outlets. I have started with iBoot and iBootBar since I have test hardware.  Hardware configuration is beyond the scope of this group of packages as most power outlets have functional web based or command line configuration tools.

=head2 FUTURE

I hope to integrate with services like IFTTT (ifttt.com).  I would appreciate community support to help develop drivers for USB controlled power strips and serial devices like the X10 family.

=head2 Home Assistant

Integration with Home Assistant L<https://home-assistant.io/> should be as easy as configuring a Command Line Switch. 

  switch:
    - platform: command_line
      switches:
        ibootbar_1:
          command_on: /usr/bin/power-outlet iBootBar ON host mybar.local outlet 1
          command_off: /usr/bin/power-outlet iBootBar OFF host mybar.local outlet 1
          command_state: /usr/bin/power-outlet iBootBar QUERY host mybar.local outlet 1 | /bin/grep -q ON
          friendly_name: My iBootBar Outlet 1

See L<https://home-assistant.io/components/switch.command_line/>

=head1 USAGE

The Perl one liner

  perl -MPower::Outlet -e 'print Power::Outlet->new(type=>"iBoot", host=>shift)->switch, "\n"' lamp

The included command line script

  power-outlet iBoot ON host lamp

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"iBoot",    host=>"mylamp");
  my $outlet = Power::Outlet->new(type=>"iBootBar", host=>"mybar", outlet=>1);
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

Please log on RT and send an email to the author.

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
