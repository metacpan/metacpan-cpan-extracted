use utf8;
package TaskPipe::SchemaTemplate_Project_SP500::Result::Company;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("company");
__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "ticker",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "url",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "sector",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "industry",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "address",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "date_added",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "cik",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "quote",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "created_dt",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "modified_dt",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key("id");

=head1 NAME

TaskPipe::SchemaTemplate_Project_SP500::Result::Company - schema template for the SP500 project C<company> table

=head1 DESCRIPTION

Schema Template for the error table

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
