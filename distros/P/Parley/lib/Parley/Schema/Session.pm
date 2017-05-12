package Parley::Schema::Session;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('parley.sessions');
__PACKAGE__->add_columns(qw/id session_data expires created/);
__PACKAGE__->set_primary_key('id');

1;
