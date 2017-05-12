use utf8;
package Schema::RackTables::0_17_9::Result::RackSpace;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_17_9::Result::RackSpace

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

=head1 TABLE: C<RackSpace>

=cut

__PACKAGE__->table("RackSpace");

=head1 ACCESSORS

=head2 rack_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 unit_no

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 atom

  data_type: 'enum'
  default_value: 'interior'
  extra: {list => ["front","interior","rear"]}
  is_nullable: 0

=head2 state

  data_type: 'enum'
  default_value: 'A'
  extra: {list => ["A","U","T","W"]}
  is_nullable: 0

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rack_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "unit_no",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "atom",
  {
    data_type => "enum",
    default_value => "interior",
    extra => { list => ["front", "interior", "rear"] },
    is_nullable => 0,
  },
  "state",
  {
    data_type => "enum",
    default_value => "A",
    extra => { list => ["A", "U", "T", "W"] },
    is_nullable => 0,
  },
  "object_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</rack_id>

=item * L</unit_no>

=item * L</atom>

=back

=cut

__PACKAGE__->set_primary_key("rack_id", "unit_no", "atom");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:03:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5MBD58bDMhTx8zm+pZGhtQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
