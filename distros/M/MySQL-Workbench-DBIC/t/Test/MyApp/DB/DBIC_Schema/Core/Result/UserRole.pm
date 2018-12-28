package MyApp::DB::DBIC_Schema::Core::Result::UserRole;

# ABSTRACT: Result class for UserRole

use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'UserRole' );
__PACKAGE__->add_columns(
qw/
    UserID
    RoleID
        /
);
__PACKAGE__->set_primary_key( qw/ UserID RoleID / );



__PACKAGE__->belongs_to(Gefa_User => 'MyApp::DB::DBIC_Schema::Core::Result::Gefa_User',
             { 'foreign.UserID' => 'self.UserID' });

__PACKAGE__->belongs_to(Role => 'MyApp::DB::DBIC_Schema::Core::Result::Role',
             { 'foreign.RoleID' => 'self.RoleID' });



=head1 DEPLOYMENT

=head2 sqlt_deploy_hook

These indexes are added to the table during deployment

=over 4

=item * fk_Gefa_User_has_Role_Role1_idx

=item * fk_Gefa_User_has_Role_Gefa_User_idx



=back

=cut

sub sqlt_deploy_hook {
    my ($self, $table) = @_;

    $table->add_index(
        type   => "normal",
        name   => "fk_Gefa_User_has_Role_Role1_idx",
        fields => ['RoleID'],
    );

    $table->add_index(
        type   => "normal",
        name   => "fk_Gefa_User_has_Role_Gefa_User_idx",
        fields => ['UserID'],
    );


    return 1;
}


# ---
# Put your own code below this comment
# ---

# ---

1;