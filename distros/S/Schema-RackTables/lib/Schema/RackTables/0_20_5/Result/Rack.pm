use utf8;
package Schema::RackTables::0_20_5::Result::Rack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_5::Result::Rack - VIEW

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
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<Rack>

=cut

__PACKAGE__->table("Rack");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 asset_no

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 has_problems

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 height

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 sort_order

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 thumb_data

  data_type: 'blob'
  is_nullable: 1

=head2 row_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 row_name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 location_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 location_name

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "asset_no",
  { data_type => "char", is_nullable => 1, size => 64 },
  "has_problems",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "height",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "sort_order",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "thumb_data",
  { data_type => "blob", is_nullable => 1 },
  "row_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "row_name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "location_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "location_name",
  { data_type => "char", is_nullable => 1, size => 255 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6b3faiawO06qDdesykFYUg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
