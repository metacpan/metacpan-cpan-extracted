package RackTables::Schema::Result::viewIPv4AddressRange;

use Moose;
use MooseX::NonMoose;
use RackTables::Types;
use namespace::autoclean;
extends 'DBIx::Class::Core';


__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("ipv4_address_range");
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q{
    SELECT  name as iface, type, inet_ntoa(ip) as addr, object_id
    FROM    IPv4Allocation
    WHERE   ip between ? and ?
});


__PACKAGE__->add_columns(
    iface       => { RT_STRING, is_nullable => 0 },
    type        => { RT_STRING, is_nullable => 0 },
    addr        => { RT_STRING, is_nullable => 0 },
    object_id   => { RT_UNSIGNED },
);


__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

RackTables::Schema::Result::viewIPv4AddressNetwork

=head1 DESCRIPTION

This view is a query to find the known IP addresses within a range.


=head1 PARAMETERS

The query expects two parameters:

=over

=item *

lower bound, as a dot-quad IP address

=item *

upper bound, as a dot-quad IP address

=back


=head1 ACCESSORS

=head2 addr

string, IP address in dot-quad form

=head2 iface

string, interface name

=head2 object_id

integer, RackObject ID

=head2 type

string, address type


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

