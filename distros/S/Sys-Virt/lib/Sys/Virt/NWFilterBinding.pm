# -*- perl -*-
#
# Copyright (C) 2018 Red Hat
#
# This program is free software; You can redistribute it and/or modify
# it under either:
#
# a) the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any
#   later version,
#
# or
#
# b) the "Artistic License"
#
# The file "LICENSE" distributed along with this file provides full
# details of the terms and conditions of the two licenses.

=pod

=head1 NAME

Sys::Virt::NWFilterBinding - Represent & manage a network filter binding

=head1 DESCRIPTION

The C<Sys::Virt::NWFilterBinding> module represents a binding between a
network filter and a network port device.

=head1 METHODS

=over 4

=cut

package Sys::Virt::NWFilterBinding;

use strict;
use warnings;


sub _new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $con = exists $params{connection} ? $params{connection} : die "connection parameter is required";
    my $self;
    if (exists $params{portdev}) {
	$self = Sys::Virt::NWFilterBinding::_lookup_by_port_dev($con,  $params{portdev});
    } elsif (exists $params{xml}) {
	$self = Sys::Virt::NWFilterBinding::_create_xml($con,  $params{xml}, $params{flags});
    } else {
	die "portdev or xml parameters are required";
    }

    bless $self, $class;

    return $self;
}


=item my $name = $binding->get_port_dev()

Returns a string with the name of the network port device that is bound to

=item my $name = $binding->get_filter_name()

Returns a string with the name of the network filter that is bound to

=item my $xml = $binding->get_xml_description()

Returns an XML document containing a complete description of
the network's configuration

=item $binding->delete()

Unbind the network port device from the filter

=cut


1;

=back

=head2 NETWORK FILTER BINDING CREATION CONSTANTS

When creating network filter bindings zero or more of the following
constants may be used

=over 4

=item Sys::Virt::NWFilterBinding::CREATE_VALIDATE

Validate the XML document against the XML schema

=back

=head1 AUTHORS

Daniel P. Berrange <berrange@redhat.com>

=head1 COPYRIGHT

Copyright (C) 2018 Red Hat

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either the GNU General Public License as published
by the Free Software Foundation (either version 2 of the License, or at
your option any later version), or, the Artistic License, as specified
in the Perl README file.

=head1 SEE ALSO

L<Sys::Virt>, L<Sys::Virt::Error>, C<http://libvirt.org>

=cut
