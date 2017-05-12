use utf8;
package Rapi::Demo::CrudModes::DB::Result::BravoNote;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bravo_note");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "bravo_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "text",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 128,
  },
  "timestamp",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "bravo",
  "Rapi::Demo::CrudModes::DB::Result::Bravo",
  { id => "bravo_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-20 22:14:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Cio2ekGKbqcT/R/Ht1245w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
