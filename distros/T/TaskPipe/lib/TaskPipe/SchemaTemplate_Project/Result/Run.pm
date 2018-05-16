use utf8;
package TaskPipe::SchemaTemplate_Project::Result::Run;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("run");
__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "started",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "completed",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key("id");


=head1 NAME

TaskPipe::SchemaTemplate_Project::Result::Run - schema template for project C<run> table

=head1 DESCRIPTION

Schema Template for the run table

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
