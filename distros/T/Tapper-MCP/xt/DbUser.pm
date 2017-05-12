package # hide from PAUSE indexer
 DbUser;

use strict;
use warnings;

use parent 'DBIx::Class';

use lib "xt/";

__PACKAGE__->load_components("Core");
__PACKAGE__->table("dbuser");
__PACKAGE__->add_columns
    (
     "id",       { data_type => "INT",     default_value => undef, is_nullable => 0, size => 11, is_auto_increment => 1, },
     "name",     { data_type => "VARCHAR", default_value => undef, is_nullable => 0, size => 255,                        },
    );
__PACKAGE__->set_primary_key("id");

1;
