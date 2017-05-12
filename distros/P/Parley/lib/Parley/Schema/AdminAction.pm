package Parley::Schema::AdminAction;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class';
use DateTime::Format::Pg;

use Parley::App::DateTime qw( :interval );

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("parley.admin_action");
__PACKAGE__->add_columns(
  id            => { },
  name          => { },
);

__PACKAGE__->set_primary_key("id");

1;
