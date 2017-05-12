use utf8;
package Schema::RackTables::0_20_11::Result::PortVLANMode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_11::Result::PortVLANMode

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

=head1 TABLE: C<PortVLANMode>

=cut

__PACKAGE__->table("PortVLANMode");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 port_name

  data_type: 'char'
  is_foreign_key: 1
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
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 255 },
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

=head2 cached_pvm

Type: belongs_to

Related object: L<Schema::RackTables::0_20_11::Result::CachedPVM>

=cut

__PACKAGE__->belongs_to(
  "cached_pvm",
  "Schema::RackTables::0_20_11::Result::CachedPVM",
  { object_id => "object_id", port_name => "port_name" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 port_allowed_vlans

Type: has_many

Related object: L<Schema::RackTables::0_20_11::Result::PortAllowedVLAN>

=cut

__PACKAGE__->has_many(
  "port_allowed_vlans",
  "Schema::RackTables::0_20_11::Result::PortAllowedVLAN",
  {
    "foreign.object_id" => "self.object_id",
    "foreign.port_name" => "self.port_name",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlans

Type: many_to_many

Composing rels: L</port_allowed_vlans> -> vlan

=cut

__PACKAGE__->many_to_many("vlans", "port_allowed_vlans", "vlan");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-05-12 22:07:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VVc2lN6Y+yLvB7Nz2E3gTA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
