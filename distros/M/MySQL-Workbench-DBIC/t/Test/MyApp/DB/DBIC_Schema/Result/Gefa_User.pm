package MyApp::DB::DBIC_Schema::Result::Gefa_User;

# ABSTRACT: Result class for Gefa_User

use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'Gefa_User' );
__PACKAGE__->add_columns(
qw/
    UserID
    Username
        /
);
__PACKAGE__->set_primary_key( qw/ UserID / );


__PACKAGE__->has_many(UserRole => 'MyApp::DB::DBIC_Schema::Result::UserRole',
             { 'foreign.UserID' => 'self.UserID' });





# ---
# Put your own code below this comment
# ---

# ---

1;