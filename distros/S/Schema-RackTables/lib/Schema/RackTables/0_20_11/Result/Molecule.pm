use utf8;
package Schema::RackTables::0_20_11::Result::Molecule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_11::Result::Molecule

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

=head1 TABLE: C<Molecule>

=cut

__PACKAGE__->table("Molecule");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 atoms

Type: has_many

Related object: L<Schema::RackTables::0_20_11::Result::Atom>

=cut

__PACKAGE__->has_many(
  "atoms",
  "Schema::RackTables::0_20_11::Result::Atom",
  { "foreign.molecule_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mount_operation_new_molecules

Type: has_many

Related object: L<Schema::RackTables::0_20_11::Result::MountOperation>

=cut

__PACKAGE__->has_many(
  "mount_operation_new_molecules",
  "Schema::RackTables::0_20_11::Result::MountOperation",
  { "foreign.new_molecule_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mount_operation_old_molecules

Type: has_many

Related object: L<Schema::RackTables::0_20_11::Result::MountOperation>

=cut

__PACKAGE__->has_many(
  "mount_operation_old_molecules",
  "Schema::RackTables::0_20_11::Result::MountOperation",
  { "foreign.old_molecule_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-05-12 22:07:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:blY7USGXQdT0pXve4MO7+w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
