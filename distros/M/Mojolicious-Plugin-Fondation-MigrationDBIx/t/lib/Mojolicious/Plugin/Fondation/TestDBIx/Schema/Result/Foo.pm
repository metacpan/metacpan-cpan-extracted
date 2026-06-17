package Mojolicious::Plugin::Fondation::TestDBIx::Schema::Result::Foo;

use base 'DBIx::Class::Core';

__PACKAGE__->table('foos');

__PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 100, is_nullable => 0 },
);

__PACKAGE__->set_primary_key('id');

1;
