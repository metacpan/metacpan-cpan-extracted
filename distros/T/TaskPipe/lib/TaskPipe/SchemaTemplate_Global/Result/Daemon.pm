use utf8;
package TaskPipe::SchemaTemplate_Global::Result::Daemon;

use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("daemon");


__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "pid",
  { data_type => "integer", is_nullable => 1 },
  "orig_cmd",
  { data_type => "text", is_nullable => 1 },
  "created_dt",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key("name");

=head1 NAME

TaskPipe::SchemaTemplate_Global::Result::Daemon - schema template for the global daemon table

=head1 DESCRIPTION

Schema Template for the Daemon Table - global schema template for daemon source

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
