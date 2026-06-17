package Mojolicious::Plugin::Fondation::TestDBIxAsync::Schema::Result::User;
use base 'DBIx::Class::Core';

__PACKAGE__->table('users');
__PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name  => { data_type => 'varchar', is_nullable => 0, size => 100 },
    email => { data_type => 'varchar', is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key('id');
1;
