package TestFor::DbicVisualizer::Schema::Result::AuthorThing;

use base 'DBIx::Class::Core';

__PACKAGE__->table('AuthorThing');
__PACKAGE__->add_columns(
    author_id => {
        data_type => 'int',
    },
    thing => {
        data_type => 'varchar',
        size => 100,
    },
);

__PACKAGE__->set_primary_key(qw/author_id/);

__PACKAGE__->belongs_to(author => 'TestFor::DbicVisualizer::Schema::Result::Author', 'author_id');

1;
