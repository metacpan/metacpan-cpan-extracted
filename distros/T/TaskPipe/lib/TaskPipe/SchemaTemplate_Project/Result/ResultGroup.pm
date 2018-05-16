use utf8;
package TaskPipe::SchemaTemplate_Project::Result::ResultGroup;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("result_group");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "pinterp_id",
  { data_type => "bigint", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

=head1 NAME

TaskPipe::SchemaTemplate_Project::Result::ResultGroup -schema template for the project C<result_group> table

=head1 DESCRIPTION

Schema Template for the result_group table

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


1;
