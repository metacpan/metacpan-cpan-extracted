use strict;
use warnings;
# Copyright (C) 2015  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v2 or later.

package Net::Fritz::Device;
# ABSTRACT: represents a TR064 device
$Net::Fritz::Device::VERSION = 'v0.0.7';

use Net::Fritz::Data;
use Net::Fritz::Error;
use Net::Fritz::Service;

use Moo;

with 'Net::Fritz::IsNoError';


has fritz        => ( is => 'ro' );


has xmltree      => ( is => 'ro' );


has service_list => ( is => 'lazy', init_arg => undef );

sub _build_service_list {
    my $self = shift;
    my $xml  = $self->xmltree;
    my @services;

    if (exists $xml->{serviceList}) {
	foreach my $service (@{$xml->{serviceList}->[0]->{service}}) {
	    push @services, Net::Fritz::Service->new(
		xmltree => $service,
		fritz   => $self->fritz
		);
	}
    }

    return \@services;
}


has device_list  => ( is => 'lazy', init_arg => undef );

sub _build_device_list {
    my $self = shift;
    my $xml  = $self->xmltree;
    my @devices;

    if (exists $xml->{deviceList}) {
	foreach my $device (@{$xml->{deviceList}->[0]->{device}}) {
	    push @devices, Net::Fritz::Device->new(
		xmltree => $device,
		fritz   => $self->fritz
		);
	}
    }

    return \@devices;
}


has attributes   => ( is => 'lazy', init_arg => undef );

use constant ATTRIBUTES => qw(
deviceType
friendlyName
manufacturer
manufacturerURL
modelDescription
modelName
modelNumber
modelURL
UDN
presentationURL
);

sub _build_attributes {
    my $self = shift;
    my $xml  = $self->xmltree;
    my $attributes = {};

    for my $attr (ATTRIBUTES) {
	if (exists $xml->{$attr}) {
	    $attributes->{$attr} = $xml->{$attr}->[0];
	}
    }

    return $attributes;
}


sub get_service {
    my $self = shift;
    my $type = shift;

    foreach my $service (@{$self->service_list}) {
	if ($service->serviceType eq $type) {
	    return $service;
	}
    }

    foreach my $device (@{$self->device_list}) {
	my $service = $device->get_service($type);
	if (! $service->error) {
	    return $service;
	}
    }
    
    return Net::Fritz::Error->new('service not found');
}


sub find_service {
    my $self = shift;
    my $type = shift;

    foreach my $service (@{$self->service_list}) {
	if ($service->serviceType =~ /$type/) {
	    return $service;
	}
    }

    foreach my $device (@{$self->device_list}) {
	my $service = $device->find_service($type);
	if (! $service->error) {
	    return $service;
	}
    }

    return Net::Fritz::Error->new('service not found');
}


sub find_service_names {
    my $self = shift;
    my $type = shift;

    my @found = ();

    foreach my $service (@{$self->service_list}) {
	if ($service->serviceType =~ /$type/) {
	    push @found, $service;
	}
    }

    foreach my $device (@{$self->device_list}) {
	my $data = $device->find_service_names($type);
	push @found, @{$data->data};
    }

    return Net::Fritz::Data->new(\@found);
}


sub find_device {
    my $self = shift;
    my $type = shift;

    foreach my $device (@{$self->device_list}) {
	if ($device->attributes->{deviceType} eq $type) {
	    return $device;
	}
    }
    
    foreach my $device (@{$self->device_list}) {
	my $device = $device->find_device($type);
	if (! $device->error) {
	    return $device;
	}
    }
    
    return Net::Fritz::Error->new( 'device not found' );
}


sub dump {
    my $self = shift;

    my $indent = shift;
    $indent = '' unless defined $indent;

    my $text = "${indent}Net::Fritz::Device:\n";
    $indent .= '  ';
    $text .= "${indent}modelName       = " . $self->attributes->{modelName} . "\n";
    $text .= "${indent}presentationURL = " . $self->attributes->{presentationURL} . "\n" if defined $self->attributes->{presentationURL};

    my @service_list = @{$self->service_list};
    if (@service_list) {
	$text .= "${indent}subservices    = {\n";
	foreach my $service (@service_list) {
	    $text .= $service->dump($indent . '  ');
	}
	$text .= "${indent}}\n";
    }

    my @device_list = @{$self->device_list};
    if (@device_list) {
	$text .= "${indent}subdevices      = {\n";
	foreach my $device (@device_list) {
	    $text .= $device->dump($indent . '  ');
	}
	$text .= "${indent}}\n";
    }

    return $text;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Fritz::Device - represents a TR064 device

=head1 VERSION

version v0.0.7

=head1 SYNOPSIS

    my $fritz    = Net::Fritz::Box->new();
    my $device   = $fritz->discover();

    # get services to call them later
    my $service_a = $device->get_service('DeviceInfo:1');
    my $service_b = $device->find_service('D.*Info:1');

    # get a subdevice
    my $subdevice = $device->find_device('LANDevice:1');

    # this one can give multiple results
    my $service_list = $device->find_service_names('DeviceInfo:1');
    printf "%d services found\n",
           scalar @{$service_list->data};

    # show all data
    $device->dump();

=head1 DESCRIPTION

This class represents a TR064 device that has been discovered.  A
device gives access to other subdevices (L<Net::Fritz::Device>) as
well as L<Net::Fritz::Service>s which allow interaction with a
L<Net::Fritz::Device>.

=head1 ATTRIBUTES (read-only)

=head2 fritz

A L<Net::Fritz::Box> instance containing the current configuration
information (device address, authentication etc.).

=head2 xmltree

A complex hashref containing all information about this
L<Net::Fritz::Device>.  This is the parsed form of the TR064 XML which
describes the device, it's subdevices and L<Net::Fritz::Service>s.

=head2 service_list

An arrayref of all L<Net::Fritz::Service>s that are available on this
device.

=head2 device_list

An arrayref of all subdevices (L<Net::Fritz::Device>) that are
available on this device.

=head2 attributes

A hashref that contains the most important information from the XML
device description.  This allows easier access than via L</xmltree>.
The available attributes are device-dependent.  The following
attributes are made available as keys in the hashref if present in the
XML:

=over 4

=item deviceType

=item friendlyName

=item manufacturer

=item manufacturerURL

=item modelDescription

=item modelName

=item modelNumber

=item modelURL

=item UDN

=item presentationURL

=back

=head2 error

See L<Net::Fritz::IsNoError/error>.

=head1 METHODS

=head2 new

Creates a new L<Net::Fritz::Device> object.  You propably don't have
to call this method, it's mostly used internally.  Expects parameters
in C<key =E<gt> value> form with the following keys:

=over

=item I<fritz>

L<Net::Fritz::Box> configuration object

=item I<xmltree>

device information in parsed XML format

=back

=head2 get_service(I<name>)

Returns the L<Net::Fritz::Service> whose
L<serviceType|Net::Fritz::Service/serviceType> equals I<name>.

If no matching service is found, the subdevices are searched for the
service in the order they are listed in the device XML, depth first.

If no matching service is found, a L<Net::Fritz::Error> is returned.

=head2 find_service(I<regexp>)

Returns the L<Net::Fritz::Service> whose
L<serviceType|Net::Fritz::Service/serviceType> matches I<regexp>.

If no matching service is found, the subdevices are searched for the
service in the order they are listed in the device XML, depth first.

If no matching service is found, a L<Net::Fritz::Error> is returned.

=head2 find_service_names(I<regexp>)

Returns all L<Net::Fritz::Service>s whose
L<serviceType|Net::Fritz::Service/serviceType> match I<regexp>.

Searches recursively through all subdevices in the order they are
listed in the device XML, depth first.

The resulting arrayref is wrapped in a L<Net::Fritz::Data> to allow
L<error checking|Net::Fritz::IsNoError>.  (Although no error should
ever occur, an an empty list is returned if nothing matched.)

=head2 find_device(I<name>)

Returns the L<Net::Fritz::Device> subdevice whose I<deviceType> equals
I<name>.

If no matching service is found, the subdevices are searched for the
I<deviceType> in the order they are listed in the device XML, depth
first.

If no matching device is found, a L<Net::Fritz::Error> is returned.

=head2 dump(I<indent>)

Returns some preformatted multiline information about the object.
Useful for debugging purposes, printing or logging.  The optional
parameter I<indent> is used for indentation of the output by
prepending it to every line.

Recursively descends into subdevices and services, so dumping the root
device of a L<Net::Fritz::Box/discover> should show everything that is
available.

=head2 errorcheck

See L<Net::Fritz::IsNoError/errorcheck>.

=head1 BUGS AND LIMITATIONS

B<TODO:> Method names are inconsistent: With services, C<get_*> uses
exact matching while C<find_*> uses regexp matching.  But with
devices, L</find_device> uses exact matching.  Change this to match
the service methods and add the missing variants.

B<TODO:> Rename L</find_service_names> to something like
L</find_all_service> as it's basically L</find_service> with multiple
results.  It does not return service names but services.

=head1 SEE ALSO

See L<Net::Fritz> for general information about this package,
especially L<Net::Fritz/INTERFACE> for links to the other classes.

=head1 AUTHOR

Christian Garbs <mitch@cgarbs.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Christian Garbs

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
