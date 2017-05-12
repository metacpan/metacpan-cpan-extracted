use utf8;
package Schema::RackTables::0_20_1::Result::AttributeValue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_1::Result::AttributeValue

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

=head1 TABLE: C<AttributeValue>

=cut

__PACKAGE__->table("AttributeValue");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 object_tid

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 attr_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 string_value

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 uint_value

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 float_value

  data_type: 'float'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "object_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "object_tid",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "attr_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "string_value",
  { data_type => "char", is_nullable => 1, size => 255 },
  "uint_value",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "float_value",
  { data_type => "float", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</object_id>

=item * L</attr_id>

=back

=cut

__PACKAGE__->set_primary_key("object_id", "attr_id");

=head1 RELATIONS

=head2 attribute_map

Type: belongs_to

Related object: L<Schema::RackTables::0_20_1::Result::AttributeMap>

=cut

__PACKAGE__->belongs_to(
  "attribute_map",
  "Schema::RackTables::0_20_1::Result::AttributeMap",
  { attr_id => "attr_id", objtype_id => "object_tid" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 object

Type: belongs_to

Related object: L<Schema::RackTables::0_20_1::Result::Object>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Schema::RackTables::0_20_1::Result::Object",
  { id => "object_id", objtype_id => "object_tid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1jD5IeOlWt7NO25glzF0ag


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
