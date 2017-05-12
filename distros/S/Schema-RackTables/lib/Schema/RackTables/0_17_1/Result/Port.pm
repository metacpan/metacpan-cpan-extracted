use utf8;
package Schema::RackTables::0_17_1::Result::Port;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_17_1::Result::Port

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

=head1 TABLE: C<Port>

=cut

__PACKAGE__->table("Port");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 type

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 l2address

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 reservation_comment

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 label

  data_type: 'char'
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
  "object_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "type",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "l2address",
  { data_type => "char", is_nullable => 1, size => 64 },
  "reservation_comment",
  { data_type => "char", is_nullable => 1, size => 255 },
  "label",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<l2address>

=over 4

=item * L</l2address>

=back

=cut

__PACKAGE__->add_unique_constraint("l2address", ["l2address"]);

=head2 C<object_id>

=over 4

=item * L</object_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("object_id", ["object_id", "name"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:04:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GYEqK9iIG2dUxaKBcERUxA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
