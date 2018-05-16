use utf8;
package TaskPipe::SchemaTemplate_Global::Result::Port;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("port");
__PACKAGE__->add_columns(
  "port",
  { data_type => "integer", is_nullable => 0 },
  "thread_id",
  { data_type => "bigint", is_nullable => 1 },
  "job_id",
  { data_type => "bigint", is_nullable => 1 },
  "process_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

__PACKAGE__->set_primary_key("port");

=head1 NAME

TaskPipe::SchemaTemplate_Global::Result::Port - Global Schema Template file for C<port> source

=head1 DESCRIPTION

It is not recommended to use this module directly. See the general manpages for TaskPipe.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
