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



__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("plan_key", ["plan_key", "input_key"]);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_; 
    $sqlt_table->add_index(name => 'thread_id', fields => ['thread_id']);
    $sqlt_table->add_index(name => 'parent_id', fields => ['parent_id']);   
}





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
