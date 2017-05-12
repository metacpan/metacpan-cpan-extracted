use utf8;
package Rapi::Demo::CrudModes::DB::Result::Alpha;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("alpha");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "string1",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 32,
  },
  "string2",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 64,
  },
  "number",
  { data_type => "float", default_value => \"null", is_nullable => 1 },
  "bool",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
  "date",
  { data_type => "date", default_value => \"null", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-05-30 07:42:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Fg7/PezjtMkV2pugtTyVrQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
