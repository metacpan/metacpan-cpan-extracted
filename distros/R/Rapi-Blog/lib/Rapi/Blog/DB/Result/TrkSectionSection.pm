use utf8;
package Rapi::Blog::DB::Result::TrkSectionSection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("trk_section_sections");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "section_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "subsection_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "depth",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "section",
  "Rapi::Blog::DB::Result::Section",
  { id => "section_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "subsection",
  "Rapi::Blog::DB::Result::Section",
  { id => "subsection_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-10-04 18:42:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cqlld59BvUwz8XGlZDYAXQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
