use utf8;
package TaskPipe::GlobalSchema::Result::Spawned;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TaskPipe::GlobalSchema::Result::Spawned

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

=head1 TABLE: C<spawned>

=cut

__PACKAGE__->table("spawned");

=head1 ACCESSORS

=head2 process_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 thread_id

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 job_id

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 pid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 used_by_pid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 port

  data_type: 'integer'
  is_nullable: 1

=head2 control_port

  data_type: 'integer'
  is_nullable: 1

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 info

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 temp_dir

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 last_checked

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "process_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "thread_id",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "job_id",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "pid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "used_by_pid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "port",
  { data_type => "integer", is_nullable => 1 },
  "control_port",
  { data_type => "integer", is_nullable => 1 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "info",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "temp_dir",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "last_checked",
  { data_type => "datetime", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</process_name>

=item * L</job_id>

=item * L</thread_id>

=back

=cut

__PACKAGE__->set_primary_key("process_name", "job_id", "thread_id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-03 11:05:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xLWuru1jkpuT07TTjomYLg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
