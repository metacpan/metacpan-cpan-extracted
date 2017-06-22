use utf8;
package Rapi::Blog::DB::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("tag");
__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("name");
__PACKAGE__->has_many(
  "post_tags",
  "Rapi::Blog::DB::Result::PostTag",
  { "foreign.tag_name" => "self.name" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-05-26 13:35:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C93siCyHQ1D1co2F2bqQhg

use RapidApp::Util ':all';

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

sub posts_count {
  my $self = shift;
  # In case the ResultSet has pre-loaded this value, don't do another query:
  my $preload = try{$self->get_column('posts_count')};
  defined $preload ? $preload : $self->post_tags->count
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
