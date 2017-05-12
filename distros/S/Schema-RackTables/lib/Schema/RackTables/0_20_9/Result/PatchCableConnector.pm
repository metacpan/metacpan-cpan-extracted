use utf8;
package Schema::RackTables::0_20_9::Result::PatchCableConnector;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_9::Result::PatchCableConnector

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

=head1 TABLE: C<PatchCableConnector>

=cut

__PACKAGE__->table("PatchCableConnector");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 origin

  data_type: 'enum'
  default_value: 'custom'
  extra: {list => ["default","custom"]}
  is_nullable: 0

=head2 connector

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "origin",
  {
    data_type => "enum",
    default_value => "custom",
    extra => { list => ["default", "custom"] },
    is_nullable => 0,
  },
  "connector",
  { data_type => "char", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<connector_per_origin>

=over 4

=item * L</connector>

=item * L</origin>

=back

=cut

__PACKAGE__->add_unique_constraint("connector_per_origin", ["connector", "origin"]);

=head1 RELATIONS

=head2 patch_cable_connector_compats

Type: has_many

Related object: L<Schema::RackTables::0_20_9::Result::PatchCableConnectorCompat>

=cut

__PACKAGE__->has_many(
  "patch_cable_connector_compats",
  "Schema::RackTables::0_20_9::Result::PatchCableConnectorCompat",
  { "foreign.connector_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pctypes

Type: many_to_many

Composing rels: L</patch_cable_connector_compats> -> pctype

=cut

__PACKAGE__->many_to_many("pctypes", "patch_cable_connector_compats", "pctype");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P0D+XGKbjfjBDHOElmmiew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
