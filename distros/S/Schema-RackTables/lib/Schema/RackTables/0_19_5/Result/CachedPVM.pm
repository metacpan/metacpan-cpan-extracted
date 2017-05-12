use utf8;
package Schema::RackTables::0_19_5::Result::CachedPVM;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_5::Result::CachedPVM

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

=head1 TABLE: C<CachedPVM>

=cut

__PACKAGE__->table("CachedPVM");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 port_name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 vlan_mode

  data_type: 'enum'
  default_value: 'access'
  extra: {list => ["access","trunk"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "object_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "port_name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "vlan_mode",
  {
    data_type => "enum",
    default_value => "access",
    extra => { list => ["access", "trunk"] },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</object_id>

=item * L</port_name>

=back

=cut

__PACKAGE__->set_primary_key("object_id", "port_name");

=head1 RELATIONS

=head2 cached_pavs

Type: has_many

Related object: L<Schema::RackTables::0_19_5::Result::CachedPAV>

=cut

__PACKAGE__->has_many(
  "cached_pavs",
  "Schema::RackTables::0_19_5::Result::CachedPAV",
  {
    "foreign.object_id" => "self.object_id",
    "foreign.port_name" => "self.port_name",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 object

Type: belongs_to

Related object: L<Schema::RackTables::0_19_5::Result::RackObject>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Schema::RackTables::0_19_5::Result::RackObject",
  { id => "object_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 port_vlanmode

Type: might_have

Related object: L<Schema::RackTables::0_19_5::Result::PortVLANMode>

=cut

__PACKAGE__->might_have(
  "port_vlanmode",
  "Schema::RackTables::0_19_5::Result::PortVLANMode",
  {
    "foreign.object_id" => "self.object_id",
    "foreign.port_name" => "self.port_name",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlans

Type: many_to_many

Composing rels: L</cached_pavs> -> vlan

=cut

__PACKAGE__->many_to_many("vlans", "cached_pavs", "vlan");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:02:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KGmYiTWxpDRs4YSImD623g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
