package RackTables::Schema::Result::viewAssociatedPorts;

use Moose;
use MooseX::NonMoose;
use RackTables::Types;
use namespace::autoclean;
extends 'DBIx::Class::Core';


__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("associated_ports");
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q{
    SELECT
        id,
        name,
        label,
        l2address,
        iif_id,
        (SELECT iif_name FROM PortInnerInterface WHERE id = iif_id) AS iif_name,
        type AS oif_id,
        (SELECT dict_value FROM Dictionary WHERE dict_key = type) AS oif_name,
        (
         SELECT porta FROM Link WHERE portb = id
         UNION
         SELECT portb FROM Link WHERE porta = id
        ) AS peer_port_id,
        (SELECT peer.name FROM Port peer WHERE peer.id = peer_port_id) AS peer_port_name,
        (SELECT peer.object_id FROM Port peer WHERE peer.id = peer_port_id) AS peer_object_id,
        (SELECT peer.name FROM RackObject peer WHERE peer.id = peer_object_id) AS peer_object_name,
        reservation_comment

    FROM Port
    WHERE object_id = ?
});


__PACKAGE__->add_columns(
    id                  => { RT_UNSIGNED },
    name                => { RT_STRING, is_nullable => 0 },
    label               => { RT_STRING },
    l2address           => { RT_STRING, size => 64 },
    iif_id              => { RT_UNSIGNED },
    iif_name            => { RT_STRING },
    oif_id              => { RT_UNSIGNED },
    oif_name            => { RT_STRING },
    peer_port_id        => { RT_UNSIGNED },
    peer_port_name      => { RT_STRING },
    peer_object_id      => { RT_UNSIGNED },
    peer_object_name    => { RT_STRING },
    reservation_comment => { RT_STRING },
);


__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

RackTables::Schema::Result::viewAssociatedPorts

=head1 DESCRIPTION

This view is a query to find the ports associated with a given device.


=head1 PARAMETERS

The query expects the following parameter:

=over

=item *

ID of the RackObject

=back


=head1 ACCESSORS

=head2 id

integer, port ID

=head2 name

string, port name

=head2 label

string, port label

=head2 l2address

string, port L2 address

=head2 iif_id

integer, inner interface ID

=head2 iif_name

string, inner interface name

=head2 oif_id

integer, outter interface ID

=head2 oif_name

string, outter interface name

=head2 peer_port_id

integer, peer port ID

=head2 peer_port_name

string, peer port name

=head2 peer_object_id

integer, peer object ID

=head2 peer_object_name

string, peer object name

=head2 reservation_comment

string, reservation comment


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

