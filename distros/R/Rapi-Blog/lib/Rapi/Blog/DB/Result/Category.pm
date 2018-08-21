use utf8;
package Rapi::Blog::DB::Result::Category;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("category");
__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "description",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 1024,
  },
);
__PACKAGE__->set_primary_key("name");
__PACKAGE__->has_many(
  "post_categories",
  "Rapi::Blog::DB::Result::PostCategory",
  { "foreign.category_name" => "self.name" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-08-20 20:36:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9R1QEXzoBCbh4hJhMmAztw

use RapidApp::Util ':all';
use Rapi::Blog::Util;

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

sub insert {
  my $self = shift;
  my $columns = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Create Category: PERMISSION DENIED" if ($User->id && !$User->admin);
  }
  
  $self->set_inflated_columns($columns) if $columns;
  
  $self->next::method
}

sub update {
  my $self = shift;
  my $columns = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Update Category: PERMISSION DENIED" if ($User->id && !$User->admin);
  }
  
  $self->set_inflated_columns($columns) if $columns;

  $self->next::method
}


sub delete {
  my $self = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Delete Category: PERMISSION DENIED" if ($User->id && !$User->admin);
  }
  
  $self->next::method(@_)
}


sub posts_count {
  my $self = shift;
  # In case the ResultSet has pre-loaded this value, don't do another query:
  my $preload = try{$self->get_column('posts_count')};
  defined $preload ? $preload : $self->post_categories->count
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
