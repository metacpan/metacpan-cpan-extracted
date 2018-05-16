use utf8;
package TaskPipe::SchemaTemplate_Project::Result::XBranchError;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("xbranch_error");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "xbranch_id",
  { data_type => "bigint", is_nullable => 1 },
  "error_id",
  { data_type => "bigint", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("xbranch_id", ["xbranch_id", "error_id"]);

=head1 NAME

TaskPipe::SchemaTemplate_Project::Result::XBranchError - schema template for project C<xbranch_error> table

=head1 DESCRIPTION

Schema Template for the xbranch_error table

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
