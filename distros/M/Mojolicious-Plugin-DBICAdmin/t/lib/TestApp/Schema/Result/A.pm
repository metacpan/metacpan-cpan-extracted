package TestApp::Schema::Result::A;
use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('A');
__PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    col1 => { data_type => 'varchar' },
    col2 => { data_type => 'varchar' },
);

__PACKAGE__->set_primary_key(qw/id/);
1;
