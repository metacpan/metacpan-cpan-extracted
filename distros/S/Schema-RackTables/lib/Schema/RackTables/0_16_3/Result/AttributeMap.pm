use utf8;
package Schema::RackTables::0_16_3::Result::AttributeMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_16_3::Result::AttributeMap

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

=head1 TABLE: C<AttributeMap>

=cut

__PACKAGE__->table("AttributeMap");

=head1 ACCESSORS

=head2 objtype_id

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 attr_id

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 chapter_no

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "objtype_id",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "attr_id",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "chapter_no",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<objtype_id>

=over 4

=item * L</objtype_id>

=item * L</attr_id>

=back

=cut

__PACKAGE__->add_unique_constraint("objtype_id", ["objtype_id", "attr_id"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:04:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rS6A9Vlk+VQPdPebyB2zIg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
