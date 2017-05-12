package MyAppDB::Role;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('roles');
# Set columns in table
__PACKAGE__->add_columns(qw/id role/);
# Set the primary key for the table
__PACKAGE__->set_primary_key('id');

#
# Set relationships:
#

# has_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *foreign* table
__PACKAGE__->has_many(map_user_role => 'MyAppDB::UserRole', 'role_id');


=head1 NAME

MyAppDB::Role - A model object representing a class of access permissions to 
the system.

=head1 DESCRIPTION

This is an object that represents a row in the 'roles' table of your 
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

For Catalyst, this is designed to be used through MyApp::Model::MyAppDB.
"Offline" utilities may wish to use this class directly.

=cut

1;
