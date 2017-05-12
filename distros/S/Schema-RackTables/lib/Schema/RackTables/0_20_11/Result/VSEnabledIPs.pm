use utf8;
package Schema::RackTables::0_20_11::Result::VSEnabledIPs;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_11::Result::VSEnabledIPs

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

=head1 TABLE: C<VSEnabledIPs>

=cut

__PACKAGE__->table("VSEnabledIPs");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vs_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vip

  data_type: 'varbinary'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 rspool_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 prio

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 vsconfig

  data_type: 'text'
  is_nullable: 1

=head2 rsconfig

  data_type: 'text'
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
  "vs_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "vip",
  { data_type => "varbinary", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "rspool_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "prio",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "vsconfig",
  { data_type => "text", is_nullable => 1 },
  "rsconfig",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</object_id>

=item * L</vs_id>

=item * L</vip>

=item * L</rspool_id>

=back

=cut

__PACKAGE__->set_primary_key("object_id", "vs_id", "vip", "rspool_id");

=head1 RELATIONS

=head2 object

Type: belongs_to

Related object: L<Schema::RackTables::0_20_11::Result::Object>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Schema::RackTables::0_20_11::Result::Object",
  { id => "object_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 rspool

Type: belongs_to

Related object: L<Schema::RackTables::0_20_11::Result::IPv4RSPool>

=cut

__PACKAGE__->belongs_to(
  "rspool",
  "Schema::RackTables::0_20_11::Result::IPv4RSPool",
  { id => "rspool_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 vsip

Type: belongs_to

Related object: L<Schema::RackTables::0_20_11::Result::VSIPs>

=cut

__PACKAGE__->belongs_to(
  "vsip",
  "Schema::RackTables::0_20_11::Result::VSIPs",
  { vip => "vip", vs_id => "vs_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-05-12 22:07:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CbfPp0U1yQP75tkE7+7CPw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
