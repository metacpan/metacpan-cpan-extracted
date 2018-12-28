package MyApp::DB::DBIC_Schema::Core::Result::Role;

# ABSTRACT: Result class for Role

use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'Role' );
__PACKAGE__->add_columns(
qw/
    RoleID
    Rolename
        /
);
__PACKAGE__->set_primary_key( qw/ RoleID / );


__PACKAGE__->has_many(UserRole => 'MyApp::DB::DBIC_Schema::Core::Result::UserRole',
             { 'foreign.RoleID' => 'self.RoleID' });





# ---
# Put your own code below this comment
# ---

# ---

1;