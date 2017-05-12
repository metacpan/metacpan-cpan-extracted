package TestFor::DbicVisualizer::Schema::Result::Book;

use base 'DBIx::Class::Core';

__PACKAGE__->table('Book');
__PACKAGE__->add_columns(
    book_id => {
        data_type => 'int',
        is_auto_increment => 1,
    },
    isbn => {
        data_type => 'varchar',
        size => 13,
    },
    title => {
        data_type => 'varchar',
    },
);

__PACKAGE__->set_primary_key(qw/book_id/);

__PACKAGE__->has_many(book_authors => 'TestFor::DbicVisualizer::Schema::Result::BookAuthor', 'book_id');
__PACKAGE__->many_to_many(authors => 'book_authors', 'author_id');

1;
