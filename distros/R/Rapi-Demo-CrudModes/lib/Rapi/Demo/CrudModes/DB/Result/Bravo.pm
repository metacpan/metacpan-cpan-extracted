use utf8;
package Rapi::Demo::CrudModes::DB::Result::Bravo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bravo");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "price",
  {
    data_type => "decimal",
    default_value => \"null",
    is_nullable => 1,
    size => [8, 2],
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("title_unique", ["title"]);
__PACKAGE__->has_many(
  "bravo_notes",
  "Rapi::Demo::CrudModes::DB::Result::BravoNote",
  { "foreign.bravo_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-20 22:14:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Xvfb5Ivd8WzCa4ffCzNjiQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
