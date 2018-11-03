use utf8;
package TaskPipe::SchemaTemplate_Project_Test::Result::Company;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("company");
__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "city_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "label",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "modified_dt",
  { data_type => "datetime", is_nullable => 1 },
  "created_dt",
  { data_type => "datetime", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "city",
  "TaskPipe::SchemaTemplate_Project_Test::Result::City",
  { id => "city_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->has_many(
  "employees",
  "TaskPipe::SchemaTemplate_Project_Test::Result::Employee",
  { "foreign.company_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
