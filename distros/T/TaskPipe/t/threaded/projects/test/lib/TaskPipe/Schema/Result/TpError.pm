use utf8;
package TaskPipe::Schema::Result::TpError;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TaskPipe::Schema::Result::TpError

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

=head1 TABLE: C<tp_error>

=cut

__PACKAGE__->table("tp_error");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 job_id

  data_type: 'bigint'
  is_nullable: 1

=head2 history_index

  data_type: 'bigint'
  is_nullable: 1

=head2 tag

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 task_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 input_dd

  data_type: 'text'
  is_nullable: 1

=head2 param_dd

  data_type: 'text'
  is_nullable: 1

=head2 pinterp_dd

  data_type: 'text'
  is_nullable: 1

=head2 xbranch_ids

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 thread_id

  data_type: 'bigint'
  is_nullable: 1

=head2 message

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "job_id",
  { data_type => "bigint", is_nullable => 1 },
  "history_index",
  { data_type => "bigint", is_nullable => 1 },
  "tag",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "task_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "input_dd",
  { data_type => "text", is_nullable => 1 },
  "param_dd",
  { data_type => "text", is_nullable => 1 },
  "pinterp_dd",
  { data_type => "text", is_nullable => 1 },
  "xbranch_ids",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "thread_id",
  { data_type => "bigint", is_nullable => 1 },
  "message",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-18 10:49:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yE08b4mvoyJh5HuDhY7/zw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
