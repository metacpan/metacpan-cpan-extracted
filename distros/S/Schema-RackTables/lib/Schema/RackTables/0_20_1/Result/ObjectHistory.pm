use utf8;
package Schema::RackTables::0_20_1::Result::ObjectHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_1::Result::ObjectHistory

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

=head1 TABLE: C<ObjectHistory>

=cut

__PACKAGE__->table("ObjectHistory");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 label

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 objtype_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

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

=head2 ctime

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 user_name

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "label",
  { data_type => "char", is_nullable => 1, size => 255 },
  "objtype_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
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
  "ctime",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "user_name",
  { data_type => "char", is_nullable => 1, size => 64 },
);

=head1 RELATIONS

=head2 id

Type: belongs_to

Related object: L<Schema::RackTables::0_20_1::Result::Object>

=cut

__PACKAGE__->belongs_to(
  "id",
  "Schema::RackTables::0_20_1::Result::Object",
  { id => "id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1tpRU8nC0u2D8ObAwQamvQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
