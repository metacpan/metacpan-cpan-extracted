use utf8;
package Schema::RackTables::0_19_13::Result::PortInterfaceCompat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_13::Result::PortInterfaceCompat

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

=head1 TABLE: C<PortInterfaceCompat>

=cut

__PACKAGE__->table("PortInterfaceCompat");

=head1 ACCESSORS

=head2 iif_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 oif_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "iif_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "oif_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<pair>

=over 4

=item * L</iif_id>

=item * L</oif_id>

=back

=cut

__PACKAGE__->add_unique_constraint("pair", ["iif_id", "oif_id"]);

=head1 RELATIONS

=head2 iif

Type: belongs_to

Related object: L<Schema::RackTables::0_19_13::Result::PortInnerInterface>

=cut

__PACKAGE__->belongs_to(
  "iif",
  "Schema::RackTables::0_19_13::Result::PortInnerInterface",
  { id => "iif_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 ports

Type: has_many

Related object: L<Schema::RackTables::0_19_13::Result::Port>

=cut

__PACKAGE__->has_many(
  "ports",
  "Schema::RackTables::0_19_13::Result::Port",
  { "foreign.iif_id" => "self.iif_id", "foreign.type" => "self.oif_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:02:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3vKmTSUcoC1VCYjzr7HKtQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
