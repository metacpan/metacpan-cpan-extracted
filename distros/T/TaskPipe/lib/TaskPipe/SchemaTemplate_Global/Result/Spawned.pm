use utf8;
package TaskPipe::SchemaTemplate_Global::Result::Spawned;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("spawned");

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
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key("process_name", "job_id", "thread_id");

=head1 NAME

TaskPipe::SchemaTemplate_Global::Result::Spawned - global schema template for C<spawned> source

=head1 DESCRIPTION

Schema Template for the spawned table

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
