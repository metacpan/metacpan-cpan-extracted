use utf8;
package TaskPipe::SchemaTemplate_Global::Result::Job;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("job");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "project",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "shell",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "orig_cmd",
  { data_type => "text", is_nullable => 1 },
  "created_dt",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key("id");


=head1 NAME

TaskPipe::SchemaTemplate_Global::Result::Job - global schema template for C<job> source

=head1 DESCRIPTION

Schema Template for the job table

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


1;
