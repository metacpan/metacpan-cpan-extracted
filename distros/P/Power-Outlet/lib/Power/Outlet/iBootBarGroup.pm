package Power::Outlet::iBootBarGroup;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::SNMP};
use List::MoreUtils qw{any all};
use Time::HiRes qw{sleep};

our $VERSION          = '0.47';
our $_oid_outletEntry = '1.3.6.1.4.1.1418.4.3.1'; #enterprises.dataprobe.iBootBarAgent.outletTable.outletEntry

=head1 NAME

Power::Outlet::iBootBarGroup - Control and query multiple Dataprobe iBootBar power outlets together

=head1 SYNOPSIS

  my $outlet=Power::Outlet::iBootBarGroup->new(
                                               host      => "mybar",
                                               outlets   => "1,2,3,4"
                                               community => "private",
                                              );
  print $outlet->query, "\n"; #any on
  print $outlet->on   , "\n"; #all on
  print $outlet->off  , "\n"; #all off

=head1 DESCRIPTION
 
Power::Outlet::iBootBar is a package for controlling and querying multiple outlets together on a Dataprobe iBootBar network attached power outlet.

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

  my $outlet=Power::Outlet->new(type=>"iBootBarGroup", "host=>"mylamp", outlets=>"1,2,3,4");
  my $outlet=Power::Outlet::iBootBarGroup->new(host=>"mylamp", outlets=>"1,2,3,4");

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

  my $community = $outlet->community("private"); #read/write
  my $community = $outlet->community("public");  #read only features

Note: Set SNMP community via telnet User Name: admin, Password: admin then "help snmp"

  set snmp writecommunity private
  set snmp readcommunity public
  set snmp 1 enable yes

=cut

sub _community_default {"private"};

=head2 outlets

Sets and returns the outlets CSV list as labeled on the back of the device.

Default: "1,2,3,4,5,6,7,8"

=cut

sub outlets {
  my $self           = shift;
  $self->{"outlets"} = shift                    if     @_;
  $self->{"outlets"} = '1,2,3,4,5,6,7,8'        unless $self->{"outlets"};
  die("Error: outlets property invalid format") unless $self->{"outlets"}  =~ m/\A([0-8]\,){0,7}[0-8]\Z/;
  return $self->{"outlets"};
}

sub _outlets_aref {[split /,/, shift->outlets]};

sub _outletIndexes {[map {$_ - 1} @{shift->_outlets_aref}]};

sub _oid_outletBuilder {
  my $self = shift;
  my $type = shift;
  return [map {join(".", $_oid_outletEntry, $type, $_)} @{$self->_outletIndexes}]; #oids so MIB is not required
}

sub _oid_outletStatus  {shift->_oid_outletBuilder('3')};
  
sub _oid_outletCommand {shift->_oid_outletBuilder('4')};

=head1 METHODS

=head2 query

Sends a TCP/IP message to the iBootBar device to query the current state

=cut

sub query {
  my $self=shift;
  if (defined wantarray) { #scalar and list context
    #status = (0 => "OFF", 1 => "ON", 2 => "REBOOT", 3 => "CYCLE", 4 => "ONPENDING", 5 => "CYCLEPENDING");
    my %return = $self->snmp_multiget($self->_oid_outletStatus);
    my @values = values %return;
    return 'ON'    if any {$_ == 1} @values; #any ON
    return 'OFF'   if all {$_ == 0} @values; #all OFF
    return 'CYCLE' if any {$_ == 3} @values; #any CYCLE
    return 'CYCLE' if any {$_ == 5} @values; #any CYCLE
    return 'UNKNOWN';
  } else { #void context
    return;
  }
}

=head2 on

Sends a TCP/IP message to the iBoot device to Turn Power ON

=cut

sub on {
  my $self = shift;
  $self->snmp_multiset($self->_oid_outletCommand, 1);
  sleep 0.4;
  return $self->query;
}

=head2 off

Sends a TCP/IP message to the iBoot device to Turn Power OFF

=cut

sub off {
  my $self = shift;
  $self->snmp_multiset($self->_oid_outletCommand, 0);
  sleep 0.4;
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
  my $self = shift;
  $self->snmp_multiset($self->_oid_outletCommand, 2);
  sleep 0.4;
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
