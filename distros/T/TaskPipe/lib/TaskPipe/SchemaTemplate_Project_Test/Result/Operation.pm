use utf8;
package TaskPipe::SchemaTemplate_Project_Test::Result::Operation;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("operations");
__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "thread_data",
  { data_type => "mediumtext", is_nullable => 1 },
  "result",
  { data_type => "mediumtext", is_nullable => 1 },
  "thread_id",
  { data_type => "bigint", is_nullable => 1 },
  "target_table",
  { data_type => "varchar", is_nullable => 1, size => 190 },
);

__PACKAGE__->set_primary_key("id");

1;
