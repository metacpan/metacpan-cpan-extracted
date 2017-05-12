use utf8;
package Schema::RackTables::0_20_11::Result::PatchCableConnectorCompat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_11::Result::PatchCableConnectorCompat

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<PatchCableConnectorCompat>

=cut

__PACKAGE__->table("PatchCableConnectorCompat");

=head1 ACCESSORS

=head2 pctype_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 connector_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "pctype_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "connector_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</pctype_id>

=item * L</connector_id>

=back

=cut

__PACKAGE__->set_primary_key("pctype_id", "connector_id");

=head1 RELATIONS

=head2 connector

Type: belongs_to

Related object: L<Schema::RackTables::0_20_11::Result::PatchCableConnector>

=cut

__PACKAGE__->belongs_to(
  "connector",
  "Schema::RackTables::0_20_11::Result::PatchCableConnector",
  { id => "connector_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 patch_cable_heap_pctype_id_end1_conns

Type: has_many

Related object: L<Schema::RackTables::0_20_11::Result::PatchCableHeap>

=cut

__PACKAGE__->has_many(
  "patch_cable_heap_pctype_id_end1_conns",
  "Schema::RackTables::0_20_11::Result::PatchCableHeap",
  {
    "foreign.end1_conn_id" => "self.connector_id",
    "foreign.pctype_id"    => "self.pctype_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 patch_cable_heap_pctype_id_end2_conns

Type: has_many

Related object: L<Schema::RackTables::0_20_11::Result::PatchCableHeap>

=cut

__PACKAGE__->has_many(
  "patch_cable_heap_pctype_id_end2_conns",
  "Schema::RackTables::0_20_11::Result::PatchCableHeap",
  {
    "foreign.end2_conn_id" => "self.connector_id",
    "foreign.pctype_id"    => "self.pctype_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pctype

Type: belongs_to

Related object: L<Schema::RackTables::0_20_11::Result::PatchCableType>

=cut

__PACKAGE__->belongs_to(
  "pctype",
  "Schema::RackTables::0_20_11::Result::PatchCableType",
  { id => "pctype_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-05-12 22:07:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DXXKDwBL3qRgxgvSUAyc2A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
