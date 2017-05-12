use utf8;
package Schema::RackTables::0_20_9::Result::PortOuterInterface;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_9::Result::PortOuterInterface

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

=head1 TABLE: C<PortOuterInterface>

=cut

__PACKAGE__->table("PortOuterInterface");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 oif_name

  data_type: 'char'
  is_nullable: 0
  size: 48

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "oif_name",
  { data_type => "char", is_nullable => 0, size => 48 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<oif_name>

=over 4

=item * L</oif_name>

=back

=cut

__PACKAGE__->add_unique_constraint("oif_name", ["oif_name"]);

=head1 RELATIONS

=head2 patch_cable_oifcompats

Type: has_many

Related object: L<Schema::RackTables::0_20_9::Result::PatchCableOIFCompat>

=cut

__PACKAGE__->has_many(
  "patch_cable_oifcompats",
  "Schema::RackTables::0_20_9::Result::PatchCableOIFCompat",
  { "foreign.oif_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 port_compat_type1s

Type: has_many

Related object: L<Schema::RackTables::0_20_9::Result::PortCompat>

=cut

__PACKAGE__->has_many(
  "port_compat_type1s",
  "Schema::RackTables::0_20_9::Result::PortCompat",
  { "foreign.type1" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 port_compat_type2s

Type: has_many

Related object: L<Schema::RackTables::0_20_9::Result::PortCompat>

=cut

__PACKAGE__->has_many(
  "port_compat_type2s",
  "Schema::RackTables::0_20_9::Result::PortCompat",
  { "foreign.type2" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 port_interface_compats

Type: has_many

Related object: L<Schema::RackTables::0_20_9::Result::PortInterfaceCompat>

=cut

__PACKAGE__->has_many(
  "port_interface_compats",
  "Schema::RackTables::0_20_9::Result::PortInterfaceCompat",
  { "foreign.oif_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pctypes

Type: many_to_many

Composing rels: L</patch_cable_oifcompats> -> pctype

=cut

__PACKAGE__->many_to_many("pctypes", "patch_cable_oifcompats", "pctype");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vnG+ML3zzLgoGajJyVM+Ug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
