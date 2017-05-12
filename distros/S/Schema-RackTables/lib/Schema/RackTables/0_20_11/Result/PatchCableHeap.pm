use utf8;
package Schema::RackTables::0_20_11::Result::PatchCableHeap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_11::Result::PatchCableHeap

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

=head1 TABLE: C<PatchCableHeap>

=cut

__PACKAGE__->table("PatchCableHeap");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 pctype_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 end1_conn_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 end2_conn_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 amount

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 length

  data_type: 'decimal'
  default_value: 1.00
  extra: {unsigned => 1}
  is_nullable: 0
  size: [5,2]

=head2 description

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "pctype_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "end1_conn_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "end2_conn_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "amount",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "length",
  {
    data_type => "decimal",
    default_value => "1.00",
    extra => { unsigned => 1 },
    is_nullable => 0,
    size => [5, 2],
  },
  "description",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 patch_cable_connector_compat_pctype_id_end1_conn_id

Type: belongs_to

Related object: L<Schema::RackTables::0_20_11::Result::PatchCableConnectorCompat>

=cut

__PACKAGE__->belongs_to(
  "patch_cable_connector_compat_pctype_id_end1_conn_id",
  "Schema::RackTables::0_20_11::Result::PatchCableConnectorCompat",
  { connector_id => "end1_conn_id", pctype_id => "pctype_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 patch_cable_connector_compat_pctype_id_end2_conn_id

Type: belongs_to

Related object: L<Schema::RackTables::0_20_11::Result::PatchCableConnectorCompat>

=cut

__PACKAGE__->belongs_to(
  "patch_cable_connector_compat_pctype_id_end2_conn_id",
  "Schema::RackTables::0_20_11::Result::PatchCableConnectorCompat",
  { connector_id => "end2_conn_id", pctype_id => "pctype_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 patch_cable_heap_logs

Type: has_many

Related object: L<Schema::RackTables::0_20_11::Result::PatchCableHeapLog>

=cut

__PACKAGE__->has_many(
  "patch_cable_heap_logs",
  "Schema::RackTables::0_20_11::Result::PatchCableHeapLog",
  { "foreign.heap_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-05-12 22:07:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/beFAGhb4BGrtBauZheCYw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
