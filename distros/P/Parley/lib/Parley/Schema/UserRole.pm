package Parley::Schema::UserRole;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('parley.user_roles');
# Set columns in table
__PACKAGE__->add_columns(qw/id authentication_id role_id/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(
    authentication => 'Parley::Schema::Authentication',
    'authentication_id'
);

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(role => 'Parley::Schema::Role', 'role_id');


__PACKAGE__->add_unique_constraint(
    'userroles_authentication_role_key',
    ['authentication_id', 'role_id']
);



1;
