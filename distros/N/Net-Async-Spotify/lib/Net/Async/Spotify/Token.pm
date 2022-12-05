package Net::Async::Spotify::Token;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

use Log::Any qw($log);
use Time::Moment;

=encoding utf8

=head1 NAME

Net::Async::Spotify::Token - Representation for Spotify Token Object

=head1 SYNOPSIS

    use Net::Async::Spotify::Token;

    my $token = Net::Async::Spotify::Token->new(
        access_token  => "NgCXRK...MzYjw",
        token_type    => "Bearer",
        scope         => "user-read-private user-read-email",
        expires_in    => 3600,
        refresh_token => "NgAagA...Um_SHo",
    );

    my $time_obtained = $token->updated_at->epoch;
    my $auth_header = $token->header_string;
    # Bearer NgCXRK...MzYjw

    my $new_token = {access_token => 'NEW...ONE',}; # can have the reset of params.
    $token->renew($new_token);
    my $new_time = $token->updated_at->epoch;

=head1 DESCRIPTION

Class representing Spotify Token Object. Adds some functionality to Token object where it's easier to deal with.
More details about Token itself, L<RFC-6749|http://tools.ietf.org/html/rfc6749#section-4.1>.

=head1 PARAMETERS

=over 4

=item access_token

Spotify App User access_token

=item refresh_token

Spotify App User refresh_token

=item token_type

Spotify Token type, usually it's set to `Bearer` when used with Access Token.
However it's also set to `Basic` when used with Authentication.

=item expires_in

Token validity in seconds from obtained time. set in C<updated_at>

=item scope

Spotify App User token allowed scope list
L<https://developer.spotify.com/documentation/general/guides/scopes/>

=back

=head1 METHODS

=cut

sub new {
    my ( $class, %args ) = @_;

    my $self = bless \%args, $class;

    $self->access_token($self->{access_token}) if exists $self->{access_token};
    $self->scope($self->{scope}) if exists $self->{scope};

    return $self;
}

=head2 renew

call this method while passing a new Token hash, to update the current Token Object.
Accepts the same hash that you'd pass it in C<new()>.

=cut

sub renew {
    my ( $self, $args ) = @_;
    for my $key ( keys %$args ) {
        $self->$key($args->{$key}) if $self->can($key);
    }
}

=head2 access_token

Mutator for Spotify User's Access Token, every time its set C<updated_at> field will be set to the current time.
It will return the current set  Spotify Access Token.

=cut

sub access_token {
    my ( $self, $token ) = @_;
    if ( defined $token ) {
        $self->{access_token} = $token;
        $self->{updated_at} = Time::Moment->now;
    }

    # By design we will allow a Token object to exists without an access_token
    # Mainly because we want to use its default expires_in field.
    # so just warn if tried to ues empty access_token
    $log->warn('Attempting to use a not yet set access_token') unless defined $self->{access_token};

    return $self->{access_token};
}

=head2 updated_at

it will return L<Time::Moment> Object, indicating Spotify Access Token last set time.

=cut

sub updated_at { shift->{updated_at} }

=head2 refresh_token

set and get, or just get the current Spotify user's Refresh Token

=cut

sub refresh_token {
    my ( $self, $token ) = @_;

    $self->{refresh_token} = $token if defined $token;

    return $self->{refresh_token};
}

=head2 token_type

set and get, or just get the Token type, default is set to `Bearer`

=cut

sub token_type {
    my ( $self, $type ) = @_;

    $self->{token_type} = $type if defined $type;
    # Set it to default if not set.
    return $self->{token_type} //= 'Bearer';
}

=head2 expires_in

set and get, or just get the Token expires_in filed. Default is set to 3600 (seconds)

=cut

sub expires_in {
    my ( $self, $expiry ) = @_;

    $self->{expires_in} = $expiry if defined $expiry;
    # Set it to default if not set
    return $self->{expires_in} //= 3600;
}

=head2 scope

set and get, or just get the configured Spotify Scopes for the Token.
Accepts a space space separated list of Scopes, or an Array reference of Scopes.
Returns an Array reference of Spotify Scopes set to Token.
L<https://developer.spotify.com/documentation/general/guides/scopes/>

=cut

sub scope {
    my ( $self, $scopes ) = @_;

    if ( defined $scopes ) {
        $self->{scope} = ref($scopes) eq 'ARRAY' ? $scopes : [ split ' ', $scopes ];
    }

    return $self->{scope};
}

=head2 header_string

Returns a String, containing the Token type and the Access Token, space separated.
Needed for Authorization header.

=cut

sub header_string {
    my $self = shift;
    return join ' ', $self->token_type, $self->access_token;
}

1;
