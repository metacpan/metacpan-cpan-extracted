package Power::Outlet::WeMo;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::HTTP::UPnP};

our $VERSION='0.24';

=head1 NAME

Power::Outlet::WeMo - Control and query a Belkin WeMo power outlet

=head1 SYNOPSIS

  my $outlet=Power::Outlet::WeMo->new(host => "mywemo");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::WeMo is a package for controlling and querying an outlet on a Belkin WeMo network attached power outlet.

=head1 USAGE

  use Power::Outlet::WeMo;
  use DateTime;
  my $lamp=Power::Outlet::WeMo->new(host=>"mywemo");
  my $hour=DateTime->now->hour;
  my $night=$hour > 20 ? 1 : $hour < 06 ? 1 : 0;
  if ($night) {
    print $lamp->on, "\n";
  } else {
    print $lamp->off, "\n";
  }

=head1 CONSTRUCTOR

=head2 new

  my $outlet=Power::Outlet->new(type=>"WeMo", "host=>"mywemo");
  my $outlet=Power::Outlet::WeMo->new(host=>"mywemo");

=head1 PROPERTIES

=head2 host

Sets and returns the hostname or IP address.

Note: Set IP address via DHCP static mapping

=cut

sub _host_default {"wemo"};

=head2 port

Sets and returns the port number.

=cut

sub _port_default {"49153"};

=head2 name

Returns the configured FriendlyName from the WeMo device

=cut

sub _name_default {
  my $self=shift;
  my $res=$self->upnp_request("Get", "FriendlyName"); #isa Net::UPnP::ActionResponse
  my $name=$res->getargumentlist->{'FriendlyName'};
  return $name;
}

sub _http_path_default {"/upnp/control/basicevent1"}; #WeMo

sub _upnp_service_type_default {"urn:Belkin:service:basicevent:1"}; #WeMo default

=head1 METHODS

=head2 query

Sends a UPnP message to the WeMo device to query the current state

=cut

sub query {
  my $self=shift;
  if (defined wantarray) { #scalar and list context
    my $res=$self->upnp_request("Get", "BinaryState"); #isa Net::UPnP::ActionResponse
    my $state=$res->getargumentlist->{'BinaryState'};
    return $state ? "ON" : "OFF";
  } else { #void context
    return;
  }
}

=head2 on

Sends a UPnP message to the WeMo device to Turn Power ON

=cut

sub on {
  my $self=shift;
  my $res=$self->upnp_request("Set", "BinaryState", "1"); #isa Net::UPnP::ActionResponse
  my $state=$res->getargumentlist->{'BinaryState'};
  return $state ? "ON" : "OFF";
}

=head2 off

Sends a UPnP message to the WeMo device to Turn Power OFF

=cut

sub off {
  my $self=shift;
  my $res=$self->upnp_request("Set", "BinaryState", "0"); #isa Net::UPnP::ActionResponse
  my $state=$res->getargumentlist->{'BinaryState'};
  return $state ? "ON" : "OFF";
}


=head2 switch

Queries the device for the current status and then requests the opposite.

=cut

#see Power::Outlet::Common->switch

=head2 cycle

Sends UPnP messages to the WeMo device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

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

=head1 COPYRIGHT

Copyright (c) 2013 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

Portions of the WeMo Implementation Copyright (c) 2013 Eric Blue

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<WebService::Belkin::Wemo::Device>, L<https://gist.github.com/jscrane/7257511>

=cut

1;
