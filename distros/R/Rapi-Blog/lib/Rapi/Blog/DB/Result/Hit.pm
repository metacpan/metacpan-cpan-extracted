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
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->has_many(
  "preauth_action_events",
  "Rapi::Blog::DB::Result::PreauthActionEvent",
  { "foreign.hit_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-28 02:04:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c1TGt5mrSyCobHmzHF8/Yg

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
