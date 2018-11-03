use utf8;
package TaskPipe::Schema::Result::TpXbranch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TaskPipe::Schema::Result::TpXbranch

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

=head1 TABLE: C<tp_xbranch>

=cut

__PACKAGE__->table("tp_xbranch");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 thread_id

  data_type: 'bigint'
  is_nullable: 1

=head2 parent_id

  data_type: 'bigint'
  is_nullable: 1

=head2 plan_key

  data_type: 'varchar'
  is_nullable: 1
  size: 190

=head2 plan_dd

  data_type: 'mediumtext'
  is_nullable: 1

=head2 input_key

  data_type: 'varchar'
  is_nullable: 1
  size: 190

=head2 input_dd

  data_type: 'mediumtext'
  is_nullable: 1

=head2 param_md5

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 param_dd

  data_type: 'mediumtext'
  is_nullable: 1

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 last_plan_index

  data_type: 'bigint'
  is_nullable: 1

=head2 last_input_index

  data_type: 'bigint'
  is_nullable: 1

=head2 last_result

  data_type: 'mediumtext'
  is_nullable: 1

=head2 branch_id

  data_type: 'varchar'
  is_nullable: 1
  size: 190

=head2 input_id

  data_type: 'varchar'
  is_nullable: 1
  size: 190

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "thread_id",
  { data_type => "bigint", is_nullable => 1 },
  "parent_id",
  { data_type => "bigint", is_nullable => 1 },
  "plan_key",
  { data_type => "varchar", is_nullable => 1, size => 190 },
  "plan_dd",
  { data_type => "mediumtext", is_nullable => 1 },
  "input_key",
  { data_type => "varchar", is_nullable => 1, size => 190 },
  "input_dd",
  { data_type => "mediumtext", is_nullable => 1 },
  "param_md5",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "param_dd",
  { data_type => "mediumtext", is_nullable => 1 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "last_plan_index",
  { data_type => "bigint", is_nullable => 1 },
  "last_input_index",
  { data_type => "bigint", is_nullable => 1 },
  "last_result",
  { data_type => "mediumtext", is_nullable => 1 },
  "branch_id",
  { data_type => "varchar", is_nullable => 1, size => 190 },
  "input_id",
  { data_type => "varchar", is_nullable => 1, size => 190 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<plan_key_input_key_unique>

=over 4

=item * L</plan_key>

=item * L</input_key>

=back

=cut

__PACKAGE__->add_unique_constraint("plan_key", ["plan_key", "input_key"]);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-28 19:18:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lzfFUhvg+wdz5NTIBnuwWg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
