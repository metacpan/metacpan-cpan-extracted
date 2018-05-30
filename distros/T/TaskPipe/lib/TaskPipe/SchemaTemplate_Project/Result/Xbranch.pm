use utf8;
package TaskPipe::SchemaTemplate_Project::Result::Xbranch;


use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("xbranch");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "thread_id",
  { data_type => "bigint", is_nullable => 1 },
  "parent_id",
  { data_type => "bigint", is_nullable => 1 },
  "plan_md5",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "plan_dd",
  { data_type => "text", is_nullable => 1 },
  "input_md5",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "input_dd",
  { data_type => "text", is_nullable => 1 },
  "param_md5",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "param_dd",
  { data_type => "text", is_nullable => 1 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "last_plan_index",
  { data_type => "bigint", is_nullable => 1 },
  "last_input_index",
  { data_type => "bigint", is_nullable => 1 },
  "last_result",
  { data_type => "text", is_nullable => 1 }
);


__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("plan_md5", ["plan_md5", "input_md5"]);


=head1 NAME

TaskPipe::SchemaTemplate_Project::Result::Xbranch - schema template for project C<xbranch> table

=head1 DESCRIPTION

Schema Template for the xbranch table

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
