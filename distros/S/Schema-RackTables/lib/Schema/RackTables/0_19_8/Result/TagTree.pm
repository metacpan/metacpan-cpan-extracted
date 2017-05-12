use utf8;
package Schema::RackTables::0_19_8::Result::TagTree;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_8::Result::TagTree

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

=head1 TABLE: C<TagTree>

=cut

__PACKAGE__->table("TagTree");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 parent_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 tag

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "parent_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "tag",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<tag>

=over 4

=item * L</tag>

=back

=cut

__PACKAGE__->add_unique_constraint("tag", ["tag"]);

=head1 RELATIONS

=head2 parent

Type: belongs_to

Related object: L<Schema::RackTables::0_19_8::Result::TagTree>

=cut

__PACKAGE__->belongs_to(
  "parent",
  "Schema::RackTables::0_19_8::Result::TagTree",
  { id => "parent_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 tag_storages

Type: has_many

Related object: L<Schema::RackTables::0_19_8::Result::TagStorage>

=cut

__PACKAGE__->has_many(
  "tag_storages",
  "Schema::RackTables::0_19_8::Result::TagStorage",
  { "foreign.tag_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tag_trees

Type: has_many

Related object: L<Schema::RackTables::0_19_8::Result::TagTree>

=cut

__PACKAGE__->has_many(
  "tag_trees",
  "Schema::RackTables::0_19_8::Result::TagTree",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:02:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YntEsLUEhZu0W3LkxgzrxQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
