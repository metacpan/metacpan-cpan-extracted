package Mojolicious::Plugin::Fondation::TestOpenAPI::Schema::Result::Bar;

use base 'DBIx::Class::Core';

__PACKAGE__->table('bars');

__PACKAGE__->add_columns(
    id           => {
        data_type => 'integer', is_auto_increment => 1, is_nullable => 0,
    },
    title        => {
        data_type => 'varchar', size => 200, is_nullable => 0,
        extra => { openapi => { minLength => 3 } },
    },
    body         => {
        data_type => 'text', is_nullable => 1,
        extra => { openapi => { maxLength => 10000 } },
    },
    count        => {
        data_type => 'integer', default_value => 0, is_nullable => 1,
        extra => { openapi => { minimum => 0 } },
    },
    is_published => {
        data_type => 'boolean', default_value => 0, is_nullable => 1,
    },
    start_date   => {
        data_type => 'date', is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

1;
