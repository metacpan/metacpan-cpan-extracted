use utf8;
package Schema::RackTables::0_20_9::Result::FileLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_9::Result::FileLink

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

=head1 TABLE: C<FileLink>

=cut

__PACKAGE__->table("FileLink");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 file_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 entity_type

  data_type: 'enum'
  default_value: 'object'
  extra: {list => ["ipv4net","ipv4rspool","ipv4vs","ipvs","ipv6net","location","object","rack","row","user"]}
  is_nullable: 0

=head2 entity_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "file_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "entity_type",
  {
    data_type => "enum",
    default_value => "object",
    extra => {
      list => [
        "ipv4net",
        "ipv4rspool",
        "ipv4vs",
        "ipvs",
        "ipv6net",
        "location",
        "object",
        "rack",
        "row",
        "user",
      ],
    },
    is_nullable => 0,
  },
  "entity_id",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<FileLink-unique>

=over 4

=item * L</file_id>

=item * L</entity_type>

=item * L</entity_id>

=back

=cut

__PACKAGE__->add_unique_constraint("FileLink-unique", ["file_id", "entity_type", "entity_id"]);

=head1 RELATIONS

=head2 file

Type: belongs_to

Related object: L<Schema::RackTables::0_20_9::Result::File>

=cut

__PACKAGE__->belongs_to(
  "file",
  "Schema::RackTables::0_20_9::Result::File",
  { id => "file_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lSmGVCdKDzTu/h67K6bawg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
