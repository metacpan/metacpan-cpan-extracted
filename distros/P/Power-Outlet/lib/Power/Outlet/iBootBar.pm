package Power::Outlet::iBootBar;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::SNMP};
use Time::HiRes qw{sleep};

our $VERSION          = '0.46';
our $_oid_outletEntry = '1.3.6.1.4.1.1418.4.3.1'; #enterprises.dataprobe.iBootBarAgent.outletTable.outletEntry

=head1 NAME

Power::Outlet::iBootBar - Control and query a Dataprobe iBootBar power outlet

=head1 SYNOPSIS

  my $outlet=Power::Outlet::iBootBar->new(
                                          host      => "mybar",
                                          outlet    => 1,
                                          community => "private",
                                         );
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION
 
Power::Outlet::iBootBar is a package for controlling and querying an outlet on a Dataprobe iBootBar network attached power outlet.

=head1 USAGE

  use Power::Outlet::iBootBar;
  use DateTime;
  my $lamp=Power::Outlet::iBootBar->new(host=>"mybar", outlet=>1);
  my $hour=DateTime->now->hour;
  my $night=$hour > 20 ? 1 : $hour < 06 ? 1 : 0;
  if ($night) {
    print $lamp->on, "\n";
  } else {
    print $lamp->off, "\n";
  }

=head1 CONSTRUCTOR

=head2 new

  my $outlet=Power::Outlet->new(type=>"iBootBar", "host=>"mylamp");
  my $outlet=Power::Outlet::iBootBar->new(host=>"mylamp");

=head1 PROPERTIES

=head2 host

Sets and returns the hostname or IP address.

Manufacturer Default: 192.168.0.254

Note: Set IP address via telnet User Name: admin, Password: admin then "help network"

  set ipmode dhcp

OR

  set ipmode static
  set ipaddress 192.168.0.254
  set subnet 255.255.255.0
  set gateway 192.168.0.1

=cut

sub _host_default {"192.168.0.254"};

=head2 community

Sets and returns the SNMP community.

  my $community=$outlet->community("private"); #read/write
  my $community=$outlet->community("public");  #read only features

Note: Set SNMP community via telnet User Name: admin, Password: admin then "help snmp"

  set snmp writecommunity private
  set snmp readcommunity public
  set snmp 1 enable yes

=cut

sub _community_default {"private"};

=head2 outlet

Sets and returns the outlet number as labeled on the back of the device.

Default: 1

=cut

sub outlet {
  my $self=shift;
  $self->{"outlet"}=shift if @_;
  $self->{"outlet"}=1 unless defined $self->{"outlet"};
  die("Error: outlet property must be set from 1 to 8.") unless $self->{"outlet"} =~ m/\A[1-8]\Z/;
  return $self->{"outlet"};
}

sub _outletIndex {shift->outlet - 1};

sub _oid_outletStatus {
  my $self=shift;
  return join(".", $_oid_outletEntry, "3", $self->_outletIndex); #oids so MIB is not required
}

sub _oid_outletCommand {
  my $self=shift;
  return join(".", $_oid_outletEntry, "4", $self->_outletIndex); #oids so MIB is not required
}

sub _oid_outletName {
  my $self=shift;
  return join(".", $_oid_outletEntry, "2", $self->_outletIndex); #oids so MIB is not required
}

=head2 name

Returns the name from the iBootBar outletName via SNMP

  $ telnet iBootBar

  iBootBar Rev 1.5d.275

  User Name:  admin
  Password:  *****

  iBootBar > help outlet
  ...
  set outlet <1-8> name <name>
  ...

  iBootBar > set outlet 1 name "Bar 1"

=cut

sub _name_default {
  my $self=shift;
  my $value=$self->snmp_get($self->_oid_outletName); #this value is cached in the super class
  return $value;
}

=head1 METHODS

=head2 query

Sends a TCP/IP message to the iBootBar device to query the current state

=cut

sub query {
  my $self=shift;
  if (defined wantarray) { #scalar and list context
    my %status=(0 => "OFF", 1 => "ON", 2 => "REBOOT", 3 => "CYCLE", 4 => "ONPENDING", 5 => "CYCLEPENDING");
    my $value=$self->snmp_get($self->_oid_outletStatus);
    return $status{$value} || "UNKNOWN($value)";
  } else { #void context
    return;
  }
}

=head2 on

Sends a TCP/IP message to the iBoot device to Turn Power ON

=cut

sub on {
  my $self=shift;
  $self->snmp_set($self->_oid_outletCommand, 1);
  sleep 0.1;
  return $self->query;
}

=head2 off

Sends a TCP/IP message to the iBoot device to Turn Power OFF

=cut

sub off {
  my $self=shift;
  $self->snmp_set($self->_oid_outletCommand, 0);
  sleep 0.1;
  return $self->query;
}


=head2 switch

Queries the device for the current status and then requests the opposite.  

=cut

#see Power::Outlet::Common->switch

=head2 cycle

Sends a TCP/IP message to the iBoot device to Cycle Power (ON-OFF-ON or OFF-ON-OFF). Cycle time is determined by Setup.

Manufacturer Default Cycle Period: 10 seconds

=cut

sub cycle {
  my $self=shift;
  $self->snmp_set($self->_oid_outletCommand, 2);
  sleep 0.1;
  return $self->query;

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

=cut

1;
