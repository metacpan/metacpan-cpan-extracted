use utf8;
package TaskPipe::GlobalSchema::Result::Thread;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TaskPipe::GlobalSchema::Result::Thread

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

=head1 TABLE: C<thread>

=cut

__PACKAGE__->table("thread");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_nullable: 0

=head2 job_id

  data_type: 'bigint'
  is_nullable: 0

=head2 parent_id

  data_type: 'bigint'
  is_nullable: 1

=head2 pid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 parent_pid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 data

  data_type: 'mediumtext'
  is_nullable: 1

=head2 last_forked

  data_type: 'datetime'
  is_nullable: 1

=head2 last_checked

  data_type: 'datetime'
  is_nullable: 1

=head2 token

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 last_task

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_nullable => 0 },
  "job_id",
  { data_type => "bigint", is_nullable => 0 },
  "parent_id",
  { data_type => "bigint", is_nullable => 1 },
  "pid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "parent_pid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "data",
  { data_type => "mediumtext", is_nullable => 1 },
  "last_forked",
  { data_type => "datetime", is_nullable => 1 },
  "last_checked",
  { data_type => "datetime", is_nullable => 1 },
  "token",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "last_task",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=item * L</job_id>

=back

=cut

__PACKAGE__->set_primary_key("id", "job_id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-03 11:05:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D6HzgrI/T5WCtwLwbNtxEA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
