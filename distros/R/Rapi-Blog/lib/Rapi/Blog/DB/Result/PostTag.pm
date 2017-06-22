use utf8;
package Rapi::Blog::DB::Result::PostTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("post_tag");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "post_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tag_name",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "post",
  "Rapi::Blog::DB::Result::Post",
  { id => "post_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "tag_name",
  "Rapi::Blog::DB::Result::Tag",
  { name => "tag_name" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-05-26 13:35:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1X1Cff0uOuglwA9boBo+IQ

use RapidApp::Util ':all';

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

sub insert {
  my $self = shift;
  my $columns = shift;
  $self->set_inflated_columns($columns) if $columns;
  
  my $kw = $self->get_column('tag_name');
  
  $self->result_source->schema
    ->resultset('Tag')
    ->find_or_create(
      { name => $kw },
      { key => 'primary' }
    );

  $self->next::method;
}



# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
