package MyApp::DB::DBIC_Schema::Result::another_comment;

# ABSTRACT: Result class for another_comment

use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'another_comment' );
__PACKAGE__->add_columns(
    comment_id => { # A column comment
        data_type          => 'INT',
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    comment_text => { # A multiline
                      # comment
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 45,
    },

);
__PACKAGE__->set_primary_key( qw/ comment_id / );






# ---
# Put your own code below this comment
# ---

# ---

1;