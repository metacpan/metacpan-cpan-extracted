use utf8;
package Schema::RackTables::0_18_4::Result::Rack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_18_4::Result::Rack

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

=head1 TABLE: C<Rack>

=cut

__PACKAGE__->table("Rack");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 row_id

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 height

  data_type: 'tinyint'
  default_value: 42
  extra: {unsigned => 1}
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 thumb_data

  data_type: 'blob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "row_id",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "height",
  {
    data_type => "tinyint",
    default_value => 42,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "thumb_data",
  { data_type => "blob", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_in_row>

=over 4

=item * L</row_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_in_row", ["row_id", "name"]);

=head1 RELATIONS

=head2 row

Type: belongs_to

Related object: L<Schema::RackTables::0_18_4::Result::RackRow>

=cut

__PACKAGE__->belongs_to(
  "row",
  "Schema::RackTables::0_18_4::Result::RackRow",
  { id => "row_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:03:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6WZBIVS9CCP+60iSE5xZPQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
