use strictures 1;
package Mojito::Auth::Role;
{
  $Mojito::Auth::Role::VERSION = '0.24';
}
use Moo::Role;
use Digest::MD5;
use MooX::Types::MooseLike::Base qw(:all);
use utf8;
use Data::Dumper::Concise;

requires 'get_user', 'add_user', 'remove_user';

=head1 Name

Mojito::Auth::Deep - common auth parts

=head1 Methods

=head2 add_user

Provide the username, realm (default Mojito) and password.


=head1 Attributes

=cut

has 'first_name' => (
    is  => 'ro',
    isa => Value,
);
has 'last_name' => (
    is  => 'ro',
    isa => Value,
);
has 'email' => (
    is  => 'ro',
    isa => Value,
);
has 'username' => (
    is  => 'ro',
    isa => Value,
);
has 'realm' => (
    is  => 'ro',
    isa => Value,
);
has 'password' => (
    is  => 'ro',
    isa => Value,
);
has 'env' => (
    is  => 'ro',
    isa => Value,
);
has 'digest_authen_cb' => (
    is      => 'ro',
    isa     => CodeRef,
    lazy    => 1,
    builder => '_build_digest_authen_cb',
);

=head1 Methods

=head2 authen_cb

The authentication callback used by Plack::Middleware::Authen::Basic.

=cut

sub authen_cb {
    my ( $username, $password ) = @_;
    return $password eq get_password_for($username);
}

=head2 _build_digest_authen_cb

The authentication callback used by Plack::Middleware::Authen::Digest.

=cut

sub _build_digest_authen_cb {
    my ($self) = @_;
    my $coderef = sub {
        my $username = shift;
        return $self->get_HA1_for($username);
    };
    return $coderef;
}

=head2 get_password_for

Given a username, return their password.

=cut

sub get_password_for {
    my ( $self, $username ) = @_;
    my $user = $self->get_user($username);
    return $user->{password};
}

=head2 get_HA1_for

Given a username, return their HA1 := md5_hex("$username:$realm:$password")

=cut

sub get_HA1_for {
    my ( $self, $username ) = @_;
    my $user = $self->get_user($username);
    return $user->{HA1};
}

=head2 secret

Used by Plack::Middleware::Auth::Digest

=cut

sub _secret () {    ## no critic
    'més_vi_si_us_plau';
}


1
