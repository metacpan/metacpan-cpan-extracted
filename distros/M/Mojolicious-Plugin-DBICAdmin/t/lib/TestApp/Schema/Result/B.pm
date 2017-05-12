package TestApp::Schema::Result::B;
use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('B');
__PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    col1 => { data_type => 'integer' },
    col2 => { data_type => 'varchar' },
);

__PACKAGE__->set_primary_key(qw/col1 col2/);

1;

