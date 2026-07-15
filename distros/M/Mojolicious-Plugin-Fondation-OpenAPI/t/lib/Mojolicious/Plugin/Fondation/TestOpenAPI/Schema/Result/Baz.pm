package Mojolicious::Plugin::Fondation::TestOpenAPI::Schema::Result::Baz;

# ABSTRACT: Pivot table fixture — should be excluded from OpenAPI via openapi_exclude

use base 'DBIx::Class::Core';

__PACKAGE__->table('bazs');

__PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    foo_id   => { data_type => 'integer', is_nullable => 0 },
    bar_id   => { data_type => 'integer', is_nullable => 0 },
);

__PACKAGE__->set_primary_key('id');

1;
