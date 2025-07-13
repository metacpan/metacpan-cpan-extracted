####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.5.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.26;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Object::Pad;

class Sys::Async::Virt::NetworkPort v0.1.1;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.1.1;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    BANDWIDTH_IN_AVERAGE  => "inbound.average",
    BANDWIDTH_IN_PEAK     => "inbound.peak",
    BANDWIDTH_IN_BURST    => "inbound.burst",
    BANDWIDTH_IN_FLOOR    => "inbound.floor",
    BANDWIDTH_OUT_AVERAGE => "outbound.average",
    BANDWIDTH_OUT_PEAK    => "outbound.peak",
    BANDWIDTH_OUT_BURST   => "outbound.burst",
};


field $_id :param :reader;
field $_client :param :reader;


method delete($flags = 0) {
    return $_client->_call(
        $remote->PROC_NETWORK_PORT_DELETE,
        { port => $_id, flags => $flags // 0 }, empty => 1 );
}

async method get_parameters($flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    my $nparams = await $_client->_call(
        $remote->PROC_NETWORK_PORT_GET_PARAMETERS,
        { port => $_id, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $_client->_call(
        $remote->PROC_NETWORK_PORT_GET_PARAMETERS,
        { port => $_id, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_NETWORK_PORT_GET_XML_DESC,
        { port => $_id, flags => $flags // 0 }, unwrap => 'xml' );
}

async method set_parameters($params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_NETWORK_PORT_SET_PARAMETERS,
        { port => $_id, params => $params, flags => $flags // 0 }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::NetworkPort - Client side proxy to remote LibVirt network port

=head1 VERSION

v0.1.1

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 delete

  await $port->delete( $flags = 0 );
  # -> (* no data *)

See documentation of L<virNetworkPortDelete|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkPortDelete>.


=head2 get_parameters

  $params = await $port->get_parameters( $flags = 0 );

See documentation of L<virNetworkPortGetParameters|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkPortGetParameters>.


=head2 get_xml_desc

  $xml = await $port->get_xml_desc( $flags = 0 );

See documentation of L<virNetworkPortGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkPortGetXMLDesc>.


=head2 set_parameters

  await $port->set_parameters( $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virNetworkPortSetParameters|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkPortSetParameters>.



=head1 INTERNAL METHODS



=head1 CONSTANTS

=over 8

=item BANDWIDTH_IN_AVERAGE

=item BANDWIDTH_IN_PEAK

=item BANDWIDTH_IN_BURST

=item BANDWIDTH_IN_FLOOR

=item BANDWIDTH_OUT_AVERAGE

=item BANDWIDTH_OUT_PEAK

=item BANDWIDTH_OUT_BURST

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
