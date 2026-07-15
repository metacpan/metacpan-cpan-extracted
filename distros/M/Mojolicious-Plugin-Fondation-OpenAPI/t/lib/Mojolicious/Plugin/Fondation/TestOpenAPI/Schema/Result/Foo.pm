package Mojolicious::Plugin::Fondation::TestOpenAPI::Schema::Result::Foo;

use base 'DBIx::Class::Core';

__PACKAGE__->table('foos');

__PACKAGE__->add_columns(
    id         => {
        data_type => 'integer', is_auto_increment => 1, is_nullable => 0,
    },
    name       => {
        data_type => 'varchar', size => 100, is_nullable => 0,
        extra => { openapi => { minLength => 3 } },
    },
    email      => {
        data_type => 'varchar', size => 200, is_nullable => 0,
        extra => { openapi => { format => 'email' } },
    },
    password   => {
        data_type => 'varchar', size => 255, is_nullable => 0,
        extra => {
            openapi => {
                writeOnly => 1,
                format    => 'password',
                minLength => 8,
                create    => { required => 1 },
                update    => { required => 0 },
            },
        },
    },
    active     => {
        data_type => 'tinyint', default_value => 1, is_nullable => 1,
        extra => { openapi => { enum => [0, 1] } },
    },
    created_at => {
        data_type => 'datetime', is_nullable => 1,
    },
    age        => {
        data_type => 'integer', is_nullable => 1,
        extra => { openapi => { minimum => 0 } },
    },
    score      => {
        data_type => 'float', is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

1;
