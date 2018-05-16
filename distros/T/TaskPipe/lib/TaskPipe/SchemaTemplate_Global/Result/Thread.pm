use utf8;
package TaskPipe::SchemaTemplate_Global::Result::Thread;
use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("thread");


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
);

__PACKAGE__->set_primary_key("id", "job_id");

=head1 NAME

TaskPipe::SchemaTemplate_Global::Result::Thread - global schema template for C<thread> source

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
