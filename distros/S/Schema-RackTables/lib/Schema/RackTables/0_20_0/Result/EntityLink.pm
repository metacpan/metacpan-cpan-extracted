use utf8;
package Schema::RackTables::0_20_0::Result::EntityLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_0::Result::EntityLink

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

=head1 TABLE: C<EntityLink>

=cut

__PACKAGE__->table("EntityLink");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 parent_entity_type

  data_type: 'enum'
  extra: {list => ["ipv4net","ipv4rspool","ipv4vs","ipv6net","location","object","rack","row","user"]}
  is_nullable: 0

=head2 parent_entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 child_entity_type

  data_type: 'enum'
  extra: {list => ["file","location","object","rack","row"]}
  is_nullable: 0

=head2 child_entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
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
  "parent_entity_type",
  {
    data_type => "enum",
    extra => {
      list => [
        "ipv4net",
        "ipv4rspool",
        "ipv4vs",
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
  "parent_entity_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "child_entity_type",
  {
    data_type => "enum",
    extra => { list => ["file", "location", "object", "rack", "row"] },
    is_nullable => 0,
  },
  "child_entity_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<EntityLink-unique>

=over 4

=item * L</parent_entity_type>

=item * L</parent_entity_id>

=item * L</child_entity_type>

=item * L</child_entity_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "EntityLink-unique",
  [
    "parent_entity_type",
    "parent_entity_id",
    "child_entity_type",
    "child_entity_id",
  ],
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CKMUVWZB12nBVSRx8DG04Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
