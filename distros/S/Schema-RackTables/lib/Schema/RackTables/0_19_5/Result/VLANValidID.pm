use utf8;
package Schema::RackTables::0_19_5::Result::VLANValidID;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_5::Result::VLANValidID

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

=head1 TABLE: C<VLANValidID>

=cut

__PACKAGE__->table("VLANValidID");

=head1 ACCESSORS

=head2 vlan_id

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "vlan_id",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</vlan_id>

=back

=cut

__PACKAGE__->set_primary_key("vlan_id");

=head1 RELATIONS

=head2 cached_pavs

Type: has_many

Related object: L<Schema::RackTables::0_19_5::Result::CachedPAV>

=cut

__PACKAGE__->has_many(
  "cached_pavs",
  "Schema::RackTables::0_19_5::Result::CachedPAV",
  { "foreign.vlan_id" => "self.vlan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 port_allowed_vlans

Type: has_many

Related object: L<Schema::RackTables::0_19_5::Result::PortAllowedVLAN>

=cut

__PACKAGE__->has_many(
  "port_allowed_vlans",
  "Schema::RackTables::0_19_5::Result::PortAllowedVLAN",
  { "foreign.vlan_id" => "self.vlan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlandescriptions

Type: has_many

Related object: L<Schema::RackTables::0_19_5::Result::VLANDescription>

=cut

__PACKAGE__->has_many(
  "vlandescriptions",
  "Schema::RackTables::0_19_5::Result::VLANDescription",
  { "foreign.vlan_id" => "self.vlan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cached_pvms

Type: many_to_many

Composing rels: L</cached_pavs> -> cached_pvm

=cut

__PACKAGE__->many_to_many("cached_pvms", "cached_pavs", "cached_pvm");

=head2 port_vlanmodes

Type: many_to_many

Composing rels: L</port_allowed_vlans> -> port_vlanmode

=cut

__PACKAGE__->many_to_many("port_vlanmodes", "port_allowed_vlans", "port_vlanmode");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:02:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J+8fPrvroI2Xnv9O4Zcfbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
