use utf8;
package Schema::RackTables::0_19_1::Result::IPv4LB;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_1::Result::IPv4LB

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

=head1 TABLE: C<IPv4LB>

=cut

__PACKAGE__->table("IPv4LB");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 rspool_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 vs_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 prio

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

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
    is_nullable => 1,
  },
  "rspool_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "vs_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "prio",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "vsconfig",
  { data_type => "text", is_nullable => 1 },
  "rsconfig",
  { data_type => "text", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<LB-VS>

=over 4

=item * L</object_id>

=item * L</vs_id>

=back

=cut

__PACKAGE__->add_unique_constraint("LB-VS", ["object_id", "vs_id"]);

=head1 RELATIONS

=head2 object

Type: belongs_to

Related object: L<Schema::RackTables::0_19_1::Result::RackObject>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Schema::RackTables::0_19_1::Result::RackObject",
  { id => "object_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 rspool

Type: belongs_to

Related object: L<Schema::RackTables::0_19_1::Result::IPv4RSPool>

=cut

__PACKAGE__->belongs_to(
  "rspool",
  "Schema::RackTables::0_19_1::Result::IPv4RSPool",
  { id => "rspool_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 v

Type: belongs_to

Related object: L<Schema::RackTables::0_19_1::Result::IPv4VS>

=cut

__PACKAGE__->belongs_to(
  "v",
  "Schema::RackTables::0_19_1::Result::IPv4VS",
  { id => "vs_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ud17CEhO8HMtU65e2g4GvQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
