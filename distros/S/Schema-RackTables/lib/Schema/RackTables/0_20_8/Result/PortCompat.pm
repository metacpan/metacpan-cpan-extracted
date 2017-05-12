use utf8;
package Schema::RackTables::0_20_8::Result::PortCompat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_8::Result::PortCompat

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

=head1 TABLE: C<PortCompat>

=cut

__PACKAGE__->table("PortCompat");

=head1 ACCESSORS

=head2 type1

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 type2

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "type1",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "type2",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<type1_2>

=over 4

=item * L</type1>

=item * L</type2>

=back

=cut

__PACKAGE__->add_unique_constraint("type1_2", ["type1", "type2"]);

=head1 RELATIONS

=head2 type1

Type: belongs_to

Related object: L<Schema::RackTables::0_20_8::Result::PortOuterInterface>

=cut

__PACKAGE__->belongs_to(
  "type1",
  "Schema::RackTables::0_20_8::Result::PortOuterInterface",
  { id => "type1" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 type2

Type: belongs_to

Related object: L<Schema::RackTables::0_20_8::Result::PortOuterInterface>

=cut

__PACKAGE__->belongs_to(
  "type2",
  "Schema::RackTables::0_20_8::Result::PortOuterInterface",
  { id => "type2" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Atb3ir57SSkAAp5NwMrTRQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
