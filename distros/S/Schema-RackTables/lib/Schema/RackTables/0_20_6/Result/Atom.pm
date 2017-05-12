use utf8;
package Schema::RackTables::0_20_6::Result::Atom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_6::Result::Atom

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

=head1 TABLE: C<Atom>

=cut

__PACKAGE__->table("Atom");

=head1 ACCESSORS

=head2 molecule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 rack_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 unit_no

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 atom

  data_type: 'enum'
  extra: {list => ["front","interior","rear"]}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "molecule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "rack_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "unit_no",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "atom",
  {
    data_type => "enum",
    extra => { list => ["front", "interior", "rear"] },
    is_nullable => 1,
  },
);

=head1 RELATIONS

=head2 molecule

Type: belongs_to

Related object: L<Schema::RackTables::0_20_6::Result::Molecule>

=cut

__PACKAGE__->belongs_to(
  "molecule",
  "Schema::RackTables::0_20_6::Result::Molecule",
  { id => "molecule_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "RESTRICT",
  },
);

=head2 rack

Type: belongs_to

Related object: L<Schema::RackTables::0_20_6::Result::Object>

=cut

__PACKAGE__->belongs_to(
  "rack",
  "Schema::RackTables::0_20_6::Result::Object",
  { id => "rack_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PFWikszxMEjJ8MvDyA9r4Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
