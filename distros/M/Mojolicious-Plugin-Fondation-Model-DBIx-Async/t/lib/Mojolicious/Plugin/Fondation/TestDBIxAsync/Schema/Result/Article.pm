package Mojolicious::Plugin::Fondation::TestDBIxAsync::Schema::Result::Article;
use base 'DBIx::Class::Core';

__PACKAGE__->table('articles');
__PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    title => { data_type => 'varchar', is_nullable => 0, size => 200 },
    body  => { data_type => 'text',   is_nullable => 1 },
);
__PACKAGE__->set_primary_key('id');
1;
