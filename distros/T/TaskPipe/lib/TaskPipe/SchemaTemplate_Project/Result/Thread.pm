use utf8;
package TaskPipe::SchemaTemplate_Project::Result::Thread;

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("thread");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "parent_id",
  { data_type => "bigint", is_nullable => 1 },
  "pid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "parent_pid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "token",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "data",
  { data_type => "mediumtext", is_nullable => 1 },
  "last_forked",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "last_checked",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "last_task",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

__PACKAGE__->set_primary_key("id");

=head1 NAME

TaskPipe::SchemaTemplate_Project::Result::Thread - schema template for project C<thread> table

=head1 DESCRIPTION

Schema Template for the thread table

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
