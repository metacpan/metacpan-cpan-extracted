use utf8;
package Schema::RackTables::0_19_14::Result::Atom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_14::Result::Atom

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
  is_nullable: 1

=head2 rack_id

  data_type: 'integer'
  extra: {unsigned => 1}
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
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "rack_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "unit_no",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "atom",
  {
    data_type => "enum",
    extra => { list => ["front", "interior", "rear"] },
    is_nullable => 1,
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:02:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aD19m6tPc08wqKRNlNlbsg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
