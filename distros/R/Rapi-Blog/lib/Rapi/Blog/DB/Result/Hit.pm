use utf8;
package Rapi::Blog::DB::Result::Hit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("hit");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "post_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ts",
  { data_type => "datetime", is_nullable => 0 },
  "client_ip",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "client_hostname",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uri",
  { data_type => "varchar", is_nullable => 1, size => 512 },
  "method",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "user_agent",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "referer",
  { data_type => "varchar", is_nullable => 1, size => 512 },
  "serialized_request",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "post",
  "Rapi::Blog::DB::Result::Post",
  { id => "post_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-05-28 12:05:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QE/NEebm+u3rIfwKLaxOog

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
