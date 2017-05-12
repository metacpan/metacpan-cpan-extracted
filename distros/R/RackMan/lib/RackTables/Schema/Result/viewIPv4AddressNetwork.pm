package RackTables::Schema::Result::viewIPv4AddressNetwork;

use Moose;
use MooseX::NonMoose;
use RackTables::Types;
use namespace::autoclean;
extends 'DBIx::Class::Core';


__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("ipv4_address_network");
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q{
    SELECT  id, ip, inet_ntoa(ip) as addr, mask, name, comment
    FROM    IPv4Network
    WHERE   ip = inet_aton(?) & (4294967295 >> (32 - mask)) << (32 - mask)
        AND mask < 32
    ORDER BY mask
});


__PACKAGE__->add_columns(
    id      => { RT_UNSIGNED },
    ip      => { RT_UNSIGNED },
    addr    => { RT_STRING, is_nullable => 0 },
    mask    => { RT_UNSIGNED },
    name    => { RT_STRING, is_nullable => 0 },
    comment => { RT_STRING },
);


__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

RackTables::Schema::Result::viewIPv4AddressNetwork

=head1 DESCRIPTION

This view is a query to find the smallest network containing
the given IP address.


=head1 PARAMETERS

The query expects the following parameter:

=over

=item *

the IP address in dot-quad form

=back


=head1 ACCESSORS

=head2 id

integer, network ID

=head2 ip

integer, IP address in numeric form

=head2 addr

string, IP address in dot-quad form

=head2 mask

integer, network mask length

=head2 name

string, network name

=head2 comment

string, comment or description, if any


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

