package RackTables::Schema::Result::viewRack;

use Moose;
use MooseX::NonMoose;
use RackTables::Types;
use namespace::autoclean;
extends "DBIx::Class::Core";


__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("rack");
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q{
    SELECT DISTINCT
        id,
        name,
        comment,
        row_id,
        (SELECT name FROM RackRow WHERE RackRow.id = row_id) AS row_name

    FROM Rack, RackSpace

    WHERE   Rack.id = RackSpace.rack_id
        AND RackSpace.object_id = ?
});


__PACKAGE__->add_columns(
    id        => { RT_UNSIGNED },
    name      => { RT_STRING, is_nullable => 0 },
    comment   => { data_type => "text" },
    row_id    => { RT_UNSIGNED },
    row_name  => { RT_STRING, is_nullable => 0 },
);


__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

RackTables::Schema::Result::viewRack

=head1 DESCRIPTION

This view is a query to find information about the physical location
of a device.


=head1 PARAMETERS

The query expects the following parameter:

=over

=item *

ID of the RackObject

=back



=head1 ACCESSORS

=head2 id

integer, rack ID

=head2 name

string, rack name

=head2 comment

text, rack comment

=head2 row_id

integer, rack row ID

=head2 row_name

string, rack row name


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

