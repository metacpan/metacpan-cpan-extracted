package Net::API::Gett::User;

use Moo;
use Carp qw(croak);
use MooX::Types::MooseLike::Base qw(Int Str);

use Net::API::Gett::Request;

our $VERSION = '1.06';

=head1 NAME

Net::API::Gett::User - Gett User object

=head1 PURPOSE

This class encapsulates Gett service user functions. You normally shouldn't instanstiate 
this class on its own as the library will create and return this object when appropriate.

=head1 ATTRIBUTES

Here are the attributes of this class.  They are read only.

=over 

=item api_key

Scalar string. C<has_api_key> predicate.

=back

=cut

has 'api_key' => ( 
    is  => 'ro',
    predicate => 'has_api_key',
    isa => Str,
);

=over 

=item email

Scalar string. C<has_email> predicate.

=back

=cut

has 'email' => (
    is  => 'ro',
    predicate => 'has_email',
    isa => sub { die "$_[0] is not email" unless $_[0] =~ /.+@.+/ },
);

=over

=item password

Scalar string. C<has_password> predicate.

=back

=cut

has 'password' => (
    is  => 'ro',
    predicate => 'has_password',
    isa => Str,
);

=over

=item access_token

Scalar string. Populated by C<login> call. C<has_access_token()> predicate.

=back 

=cut

has 'access_token' => (
    is        => 'rw',
    writer    => '_set_access_token',
    predicate => 'has_access_token',
    isa => Str,
);

=over

=item access_token_expiration

Scalar integer. Unix epoch seconds until an access token is no longer valid which is 
currently 24 hours (86400 seconds) from token acquisition. 
This value is suitable for use in a call to C<localtime()>.

=back

=cut

has 'access_token_expiration' => (
    is        => 'rw',
    writer    => '_set_access_token_expiration',
    isa => Int,
);

=over

=item refresh_token

Scalar string. Populated by C<login> call.  Can be used to generate a new valid
access token without reusing an email/password login method.  C<has_refresh_token()> 
predicate.

=back

=cut

has 'refresh_token' => (
    is        => 'rw',
    writer    => '_set_refresh_token',
    predicate => 'has_refresh_token',
    isa => Str,
);

=over

=item request

This is a L<Net::API::Gett::Request> object. Defaults to a new instance of that class.

=back

=cut

has 'request' => (
    is => 'rw',
    isa => sub { die "$_[0] is not Net::API::Gett::Request" unless ref($_[0]) =~ /Request/ },
    default => sub { Net::API::Gett::Request->new() },
    lazy => 1,
);

=over

=item userid

Scalar string.

=item fullname

Scalar string.

=item email

Scalar string.

=item storage_used

Scalar integer. In bytes.

=item storage_limit

Scalar integer. In bytes.

=back


=cut

has 'userid' => (
    is => 'rw',
    writer => '_set_userid',
    isa => Str
);

has 'fullname' => (
    is => 'rw',
    writer => '_set_fullname',
    isa => Str,
);

has 'storage_used' => (
    is => 'rw',
    isa => Int,
    writer => '_set_storage_used',
);

has 'storage_limit' => (
    is => 'rw',
    isa => Int,
    writer => '_set_storage_limit',
);

=head1 METHODS 

=over

=item login()

This method populates the C<access_token>, C<refresh_token> and C<user> attributes.  It usually
doesn't need to be explicitly called since methods which require an access token will automatically
(and lazily) attempt to log in to the API and get one.

Returns a perl hash representation of the JSON output for L<https://open.ge.tt/1/users/login>.

=back

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my %params = @_;

    unless (
           $params{refresh_token}
        || $params{access_token}
        || ( $params{api_key} && $params{email} && $params{password} ) )
    {
        die(
            "api_key, email and password are needed to create ",
            "Net::API::Gett::User object. Or you can use refresh_token ",
            "or access_token rather than api_key, email and password.\n",
        );
    }

    return $class->$orig(@_);
};

sub login {
    my $self = shift;

    my %hr;
    if ( $self->has_refresh_token ) {
        $hr{'refreshtoken'} = $self->refresh_token;
    }
    elsif ( $self->has_api_key && $self->has_email && $self->has_password ) {
        @hr{'apikey', 'email', 'password'} = (
            $self->api_key,
            $self->email,
            $self->password);
    }
    else {
        croak "I need either an api_key, email, and password or a refresh token to login";
    }

    my $response = $self->request->post('/users/login', \%hr);

    # $response is a hashref
    # see https://open.ge.tt/1/doc/rest#users/login for response keys

    if ( $response ) {
        $self->_set_access_token( $response->{'accesstoken'} );
        $self->_set_access_token_expiration( time + $response->{'expires'} );
        $self->_set_refresh_token( $response->{'refreshtoken'} );
        $self->_set_attrs( $response->{'user'} );
        return $self;
    }
    else {
        croak("No response from user->login");
    }
}

=over

=item refresh()

Refreshes user data.

=back

=cut

sub refresh {
    my $self = shift;

    $self->login unless $self->has_access_token;

    my $endpoint = "/users/me?accesstoken=" . $self->access_token;

    my $response = $self->request->get($endpoint);

    if ( $response ) {
        $self->_set_attrs($response);
        return $self;
    }
    else {
        croak("No response from user->refresh");
    }
}

sub _set_attrs {
    my $self = shift;
    my $uref = shift; # hashref https://open.ge.tt/1/doc/rest#users/me

    return undef unless ref($uref) eq "HASH";

    $self->_set_userid($uref->{'userid'});
    $self->_set_fullname($uref->{'fullname'});
    $self->_set_storage_used($uref->{'storage'}->{'used'});
    $self->_set_storage_limit($uref->{'storage'}->{'limit'}),
}

=head1 SEE ALSO

L<Net::API::Gett>

=cut

1;

