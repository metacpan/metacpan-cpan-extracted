use utf8;
package TaskPipe::SchemaTemplate_Project_Test::Result::City;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("city");
__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "label",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "created_dt",
  { data_type => "datetime", is_nullable => 1 },
  "modified_dt",
  { data_type => "datetime", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "companies",
  "TaskPipe::SchemaTemplate_Project_Test::Result::Company",
  { "foreign.city_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
