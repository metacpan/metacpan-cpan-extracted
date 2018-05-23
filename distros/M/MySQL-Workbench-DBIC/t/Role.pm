package
   MyApp::DB::DBIC_Schema::Result::Role;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'Role' );
__PACKAGE__->add_columns(
    RoleID => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    Rolename => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 45,
    },

);
__PACKAGE__->set_primary_key( qw/ RoleID / );


__PACKAGE__->has_many(UserRole => 'MyApp::DB::DBIC_Schema::Result::UserRole',
             { 'foreign.RoleID' => 'self.RoleID' });





# ---
# Put your own code below this comment
# ---
print "This is some custom code!";
# ---

1;
