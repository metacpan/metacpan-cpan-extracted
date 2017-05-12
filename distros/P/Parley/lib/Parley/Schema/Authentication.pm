package Parley::Schema::Authentication;

# Created by DBIx::Class::Schema::Loader v0.03004 @ 2006-08-10 09:12:24

use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("parley.authentication");
__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    #default_value => "nextval('authentication_authentication_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "password" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "authenticated" => {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "username" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("authentication_username_key", ["username"]);

__PACKAGE__->has_many(
  "people" => "Person",
  { "foreign.authentication_id" => "self.id" },
);

__PACKAGE__->has_many(
    map_user_role => 'Parley::Schema::UserRole',
    'authentication_id',
    { join_type => 'right' }
);
__PACKAGE__->many_to_many('roles' => 'map_user_role' => 'role');

1;
