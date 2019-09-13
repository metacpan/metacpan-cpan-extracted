use utf8;
package Rapi::Blog::DB::Result::PreauthActionEvent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("preauth_action_event");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ts",
  { data_type => "datetime", is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "action_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "hit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "info",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "action",
  "Rapi::Blog::DB::Result::PreauthAction",
  { id => "action_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "hit",
  "Rapi::Blog::DB::Result::Hit",
  { id => "hit_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->belongs_to(
  "type",
  "Rapi::Blog::DB::Result::PreauthEventType",
  { id => "type_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-28 02:04:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CTXzUj/Ria83CXwXwZqAfQ


sub insert {
  my ($self, $columns) = @_;
  $self->set_inflated_columns($columns) if $columns;
  
  $self->ts or $self->ts( Rapi::Blog::Util->now_ts );
  
  $self->next::method;
  
  return $self;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
