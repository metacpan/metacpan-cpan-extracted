use utf8;
package Schema::RackTables::0_20_5::Result::Dictionary;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_5::Result::Dictionary

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

=head1 TABLE: C<Dictionary>

=cut

__PACKAGE__->table("Dictionary");

=head1 ACCESSORS

=head2 chapter_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 dict_key

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 dict_sticky

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 1

=head2 dict_value

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "chapter_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "dict_key",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "dict_sticky",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 1,
  },
  "dict_value",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</dict_key>

=back

=cut

__PACKAGE__->set_primary_key("dict_key");

=head1 UNIQUE CONSTRAINTS

=head2 C<dict_unique>

=over 4

=item * L</chapter_id>

=item * L</dict_value>

=item * L</dict_sticky>

=back

=cut

__PACKAGE__->add_unique_constraint("dict_unique", ["chapter_id", "dict_value", "dict_sticky"]);

=head1 RELATIONS

=head2 chapter

Type: belongs_to

Related object: L<Schema::RackTables::0_20_5::Result::Chapter>

=cut

__PACKAGE__->belongs_to(
  "chapter",
  "Schema::RackTables::0_20_5::Result::Chapter",
  { id => "chapter_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fsCMnG5PRksSz1BkhtK8Ww


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
