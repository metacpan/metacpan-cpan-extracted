use utf8;
package TaskPipe::SchemaTemplate_Project::Result::Error;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("error");
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

__PACKAGE__->set_primary_key("id");

=head1 NAME

TaskPipe::SchemaTemplate_Project::Result::Error - schema template for the project C<error> table

=head1 DESCRIPTION

Schema Template for the error table

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
