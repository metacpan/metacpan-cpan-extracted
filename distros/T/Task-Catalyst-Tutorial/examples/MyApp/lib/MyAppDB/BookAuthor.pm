package MyAppDB::BookAuthor;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('book_authors');
# Set columns in table
__PACKAGE__->add_columns(qw/book_id author_id/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/book_id author_id/);

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(book => 'MyAppDB::Book', 'book_id');

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(author => 'MyAppDB::Author', 'author_id');


=head1 NAME

MyAppDB::BookAuthor - A model object representing the JOIN between an author and 
a book.

=head1 DESCRIPTION

This is an object that represents a row in the 'book_authors' table of your 
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

You probably won't need to use this class directly -- it will be automatically
used by DBIC where joins are needed.

For Catalyst, this is designed to be used through MyApp::Model::MyAppDB.
Offline utilities may wish to use this class directly.

=cut

1;
