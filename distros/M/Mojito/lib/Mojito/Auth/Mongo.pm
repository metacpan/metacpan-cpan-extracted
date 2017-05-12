use strictures 1;
package Mojito::Auth::Mongo;
{
  $Mojito::Auth::Mongo::VERSION = '0.24';
}
use Moo;
use Data::Dumper::Concise;

with('Mojito::Role::DB::Mongo');

=head1 Name

Mojito::Auth::Deep - authentication delegatee class for MongoDB

=head1 Methods

=head2 add_user

Provide the username, realm (default Mojito) and password.

=cut

sub add_user {
    my ($self, $args) = @_;
    
    my $username = $args->{username} || $self->username;
    if ($self->get_user($username)) {
        warn "Username '$username' already taken!";
        return;
    }
    my @digest_input_parts = qw/ username realm password /;
    my $digest_input       = join ':', map { $self->$_ } @digest_input_parts;
    my $HA1                = Digest::MD5::md5_hex($digest_input);
    my $md5_password       = Digest::MD5::md5_hex( $self->password );
    
    my $id                 = $self->collection->insert(
        {
            first_name => $self->first_name,
            last_name  => $self->last_name,
            email      => $self->email,
            username   => $self->username,
            realm      => $self->realm,
            HA1        => $HA1,
            password   => $md5_password
        }
    );
    return $id;
}

=head2 get_user

Get a user from the database.

=cut

sub get_user {
    my ( $self, $username ) = @_;
    $username //= $self->username;
    return if !$username;
    return $self->collection->find_one( { username => $username } );
}

=head2 remove_user

Remove a user from the database.

=cut

sub remove_user {
    my ( $self, $username ) = @_;

    $username //= $self->username;
    return if !$username;
    return $self->collection->remove({ username => $username });
}

# We compose the role AFTER the required methods are defined.
with('Mojito::Auth::Role');

=head2 BUILD

Set some things post object construction, pre object use.

=cut

sub BUILD {
    my $self = shift;

    # We use the users collection for Auth stuff
    $self->collection_name('users');
}

1
