package MyAppDB::Book;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core HTMLWidget/);
# Set the table name
__PACKAGE__->table('books');
# Set columns in table
__PACKAGE__->add_columns(qw/id title rating/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);

#
# Set relationships:
#

# has_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *foreign* table
__PACKAGE__->has_many(book_authors => 'MyAppDB::BookAuthor', 'book_id');

# many_to_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of has_many() relationship this many_to_many() is shortcut for
#     3) Name of belongs_to() relationship in model class of has_many() above 
#   You must already have the has_many() defined to use a many_to_many().
__PACKAGE__->many_to_many(authors => 'book_authors', 'author');


=head1 NAME

MyAppDB::Book - A model object representing a book.

=head1 DESCRIPTION

This is an object that represents a row in the 'books' table of your application
database.  It uses DBIx::Class (aka, DBIC) to do ORM.

For Catalyst, this is designed to be used through MyApp::Model::MyAppDB.
Offline utilities may wish to use this class directly.

=cut

1;
