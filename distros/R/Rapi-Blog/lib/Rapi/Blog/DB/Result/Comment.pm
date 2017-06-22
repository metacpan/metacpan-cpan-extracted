use utf8;
package Rapi::Blog::DB::Result::Comment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("comment");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "parent_id",
  {
    data_type      => "integer",
    default_value  => \"null",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
  "post_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ts",
  { data_type => "datetime", is_nullable => 0 },
  "body",
  { data_type => "text", default_value => "", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "comments",
  "Rapi::Blog::DB::Result::Comment",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "parent",
  "Rapi::Blog::DB::Result::Comment",
  { id => "parent_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->belongs_to(
  "post",
  "Rapi::Blog::DB::Result::Post",
  { id => "post_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "user",
  "Rapi::Blog::DB::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-05-24 12:10:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vTk0Nu215wTcvpKtY8xUcg

use RapidApp::Util ':all';
use Rapi::Blog::Util;

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

sub insert {
  my $self = shift;
  my $columns = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Insert Comment: PERMISSION DENIED" if ($User->id && !$User->can_comment);
  }
  
  $self->set_inflated_columns($columns) if $columns;
  
  $self->_set_column_defaults('insert');

  $self->next::method;
}

sub update {
  my $self = shift;
  my $columns = shift;
  $self->set_inflated_columns($columns) if $columns;
  
  $self->_set_column_defaults('update');
  
  $self->next::method;
}



sub _set_column_defaults {
  my $self = shift;
  my $for = shift || '';
  
  my $uid = Rapi::Blog::Util->get_uid;
  my $now_ts = Rapi::Blog::Util->now_ts;
    
  $self->ts($now_ts) unless $self->ts;
  $self->user_id( $uid ) unless $self->user_id;
  
  if(! $self->post_id && $self->parent_id && $self->parent) {
    $self->post_id( $self->parent->post_id );
  }
  
  if($self->parent_id && $self->post_id && $self->parent) {
    my ($p_post_id,$post_id) = ($self->parent->post_id,$self->post_id);
    die usererr join('',
      "parent/post mismatch: the post_id of the parent comment ($p_post_id) ",
      "doesn't match the supplied post_id ($post_id)"
    ) unless ( $p_post_id == $post_id );
  }
  
}

sub html_id {
  my $self = shift;
  join('','comment-',$self->id)
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
