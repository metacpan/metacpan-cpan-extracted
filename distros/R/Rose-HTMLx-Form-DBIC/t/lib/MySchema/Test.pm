package MySchema::Test;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ 
    InflateColumn::DateTime PK::Auto Core 
/);

__PACKAGE__->table("test");

__PACKAGE__->add_columns(
    hidden_col     => { data_type => "INTEGER" },
    text_col       => { data_type => "TEXT" },
    password_col   => { data_type => "TEXT" },
    checkbox_col   => {
        data_type => "TEXT",
        default_value => 0,
        is_nullable   => 0,
    },
    select_col     => { data_type => "TEXT" },
    radio_col      => { data_type => "TEXT" },
    radiogroup_col => { data_type => "TEXT" },
    date_col       => { data_type => "DATE" },
    not_in_form    => { data_type => "TEXT" },
);

__PACKAGE__->set_primary_key("hidden_col");

1;

