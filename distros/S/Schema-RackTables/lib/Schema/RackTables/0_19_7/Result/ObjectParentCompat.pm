use utf8;
package Schema::RackTables::0_19_7::Result::ObjectParentCompat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_7::Result::ObjectParentCompat

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

=head1 TABLE: C<ObjectParentCompat>

=cut

__PACKAGE__->table("ObjectParentCompat");

=head1 ACCESSORS

=head2 parent_objtype_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 child_objtype_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "parent_objtype_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "child_objtype_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<parent_child>

=over 4

=item * L</parent_objtype_id>

=item * L</child_objtype_id>

=back

=cut

__PACKAGE__->add_unique_constraint("parent_child", ["parent_objtype_id", "child_objtype_id"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:02:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YMQ8ktbsJqJtgEwMyljB1Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
