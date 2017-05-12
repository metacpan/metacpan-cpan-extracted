use utf8;
package Schema::RackTables::0_20_8::Result::PatchCableOIFCompat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_8::Result::PatchCableOIFCompat

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

=head1 TABLE: C<PatchCableOIFCompat>

=cut

__PACKAGE__->table("PatchCableOIFCompat");

=head1 ACCESSORS

=head2 pctype_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 oif_id

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
  "oif_id",
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

=item * L</oif_id>

=back

=cut

__PACKAGE__->set_primary_key("pctype_id", "oif_id");

=head1 RELATIONS

=head2 oif

Type: belongs_to

Related object: L<Schema::RackTables::0_20_8::Result::PortOuterInterface>

=cut

__PACKAGE__->belongs_to(
  "oif",
  "Schema::RackTables::0_20_8::Result::PortOuterInterface",
  { id => "oif_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 pctype

Type: belongs_to

Related object: L<Schema::RackTables::0_20_8::Result::PatchCableType>

=cut

__PACKAGE__->belongs_to(
  "pctype",
  "Schema::RackTables::0_20_8::Result::PatchCableType",
  { id => "pctype_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U+YizghZGaig8GIyPfyEWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
