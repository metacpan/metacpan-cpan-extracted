use utf8;
package Rapi::Blog::DB::Result::PreauthActionType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("preauth_action_type");
__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 16 },
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
  "preauth_actions",
  "Rapi::Blog::DB::Result::PreauthAction",
  { "foreign.type" => "self.name" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-27 23:38:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P8LCFp0JKZ2TEWFTn9Wl9g

use RapidApp::Util ':all';
use Rapi::Blog::Util;

use String::CamelCase qw/camelize/;
use Module::Runtime;

our $ACTOR_CLASS_NAMESPACE = 'Rapi::Blog::PreAuth::Actor';

sub actor_class {
  my $self = shift;
  
  my $class = join('::',$ACTOR_CLASS_NAMESPACE,camelize($self->name));    
  Module::Runtime::require_module($class);

  $class
}




# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
