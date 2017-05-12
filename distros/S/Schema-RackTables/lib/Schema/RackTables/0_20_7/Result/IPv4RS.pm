use utf8;
package Schema::RackTables::0_20_7::Result::IPv4RS;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_7::Result::IPv4RS

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

=head1 TABLE: C<IPv4RS>

=cut

__PACKAGE__->table("IPv4RS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 inservice

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 rsip

  data_type: 'varbinary'
  is_nullable: 0
  size: 16

=head2 rsport

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 rspool_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 rsconfig

  data_type: 'text'
  is_nullable: 1

=head2 comment

  data_type: 'varchar'
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
  "inservice",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "rsip",
  { data_type => "varbinary", is_nullable => 0, size => 16 },
  "rsport",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 1 },
  "rspool_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "rsconfig",
  { data_type => "text", is_nullable => 1 },
  "comment",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<pool-endpoint>

=over 4

=item * L</rspool_id>

=item * L</rsip>

=item * L</rsport>

=back

=cut

__PACKAGE__->add_unique_constraint("pool-endpoint", ["rspool_id", "rsip", "rsport"]);

=head1 RELATIONS

=head2 rspool

Type: belongs_to

Related object: L<Schema::RackTables::0_20_7::Result::IPv4RSPool>

=cut

__PACKAGE__->belongs_to(
  "rspool",
  "Schema::RackTables::0_20_7::Result::IPv4RSPool",
  { id => "rspool_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HiA1t+pKHouBnIWpjrt7Wg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
