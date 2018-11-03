use utf8;
package TaskPipe::SchemaTemplate_Global::Result::OpenProxy;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("open_proxy");
__PACKAGE__->add_columns(
  "ip",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "port",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "list_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "job_id",
  { data_type => "bigint", is_nullable => 1 },
  "thread_id",
  { data_type => "bigint", is_nullable => 1 },
  "checked_dt",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "last_used_dt",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);


__PACKAGE__->set_primary_key("ip", "port");

=head1 NAME

TaskPipe::SchemaTemplate_Global::Result::OpenProxy - global schema template for open proxy source

=head1 DESCRIPTION

Schema Template for the OpenProxy table

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
