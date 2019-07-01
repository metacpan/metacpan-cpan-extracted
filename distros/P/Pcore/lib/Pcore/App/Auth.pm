package Pcore::App::Auth;

use Pcore -role, -const, -export;
use Pcore::Util::Scalar qw[is_plain_arrayref];
use Pcore::Util::Data qw[from_b64_url];
use Pcore::Util::Digest qw[sha3_512];
use Pcore::Util::Text qw[encode_utf8];
use Pcore::Util::UUID qw[uuid_from_bin];
use Pcore::App::Auth::Descriptor;

our $EXPORT = {
    TOKEN_TYPE      => [qw[$TOKEN_TYPE_UNKNOWN $TOKEN_TYPE_PASSWORD $TOKEN_TYPE_TOKEN $TOKEN_TYPE_SESSION]],
    INVALIDATE_TYPE => [qw[$INVALIDATE_USER $INVALIDATE_TOKEN $INVALIDATE_ALL]],
    PRIVATE_TOKEN   => [qw[$PRIVATE_TOKEN_ID $PRIVATE_TOKEN_HASH $PRIVATE_TOKEN_TYPE]],
    ROOT_USER       => [qw[$ROOT_USER_NAME $ROOT_USER_ID]],
};

has app => ( required => 1 );    # ConsumerOf ['Pcore::App']

has _auth_cb_queue    => ( sub { {} }, init_arg => undef );    # HashRef
has _auth_cache_user  => ( init_arg             => undef );    # HashRef, user_id => { user_token_id }
has _auth_cache_token => ( init_arg             => undef );    # HashRef, user_token_id => auth_descriptor
has _session_timer    => ( init_arg             => undef );    # InstanceOf['AE::timer']

const our $TOKEN_TYPE_UNKNOWN  => 0;
const our $TOKEN_TYPE_PASSWORD => 1;
const our $TOKEN_TYPE_TOKEN    => 2;
const our $TOKEN_TYPE_SESSION  => 3;

const our $PRIVATE_TOKEN_ID   => 0;
const our $PRIVATE_TOKEN_HASH => 1;
const our $PRIVATE_TOKEN_TYPE => 2;

const our $INVALIDATE_USER  => 1;
const our $INVALIDATE_TOKEN => 2;
const our $INVALIDATE_ALL   => 3;

const our $SESSION_TIMEOUT => 60 * 60 * 12;    # remove sessions tokens, that are older than 12 hours

const our $ROOT_USER_NAME => 'root';
const our $ROOT_USER_ID   => 'ffffffff-ffff-ffff-ffff-ffffffffffff';

sub new ( $self, $app ) {
    state $scheme_class = {
        sqlite => 'Pcore::App::Auth::Backend::Local::sqlite',
        pgsql  => 'Pcore::App::Auth::Backend::Local::pgsql',
        ws     => 'Pcore::App::Auth::Backend::Remote',
        wss    => 'Pcore::App::Auth::Backend::Remote',
    };

    if ( defined $app->{cfg}->{auth}->{backend} ) {
        my $uri = P->uri( $app->{cfg}->{auth}->{backend} );

        if ( my $class = $scheme_class->{ $uri->{scheme} } ) {
            return P->class->load($class)->new( { app => $app } );
        }
        else {
            die 'Unknown API scheme';
        }
    }
    else {
        return P->class->load('Pcore::App::Auth::Backend::NoAuth')->new( { app => $app } );
    }
}

# setup events listeners
around init => sub ( $orig, $self ) {

    # setup events listeners
    P->bind_events(
        'app.auth.cache',
        sub ($ev) {
            if ( $ev->{data}->{type} == $INVALIDATE_USER ) {
                $self->_invalidate_user( $ev->{data}->{id} );
            }
            elsif ( $ev->{data}->{type} == $INVALIDATE_TOKEN ) {
                $self->_invalidate_token( $ev->{data}->{id} );
            }
            elsif ( $ev->{data}->{type} == $INVALIDATE_ALL ) {
                $self->_invalidate_all;
            }

            return;
        }
    );

    # expired sessions invalidation timer
    $self->{_session_timer} = AE::timer $SESSION_TIMEOUT, $SESSION_TIMEOUT, sub {
        $self->_invalidate_expired_sessions;

        return;
    };

    return $self->$orig;
};

sub user_is_root ( $self, $user_id ) {
    return $user_id eq $ROOT_USER_NAME || $user_id eq $ROOT_USER_ID;
}

# AUTHENTICATE
# parse token, create private token, forward to authenticate_private
sub authenticate ( $self, $token ) {

    # no auth token provided
    return bless { app => $self->{app} }, 'Pcore::App::Auth::Descriptor' if !defined $token;

    my ( $token_type, $token_id, $private_token_hash );

    # authenticate user password
    if ( is_plain_arrayref $token) {

        # lowercase user name
        $token->[0] = lc $token->[0];

        # generate private token hash
        $private_token_hash = eval { sha3_512 encode_utf8( $token->[1] ) . encode_utf8 $token->[0] };

        # error decoding token
        return $self->_get_unauthenticated_descriptor if $@;

        $token_type = $TOKEN_TYPE_PASSWORD;

        \$token_id = \$token->[0];
    }

    # authenticate token
    else {

        # decode token
        eval {
            my $token_bin = from_b64_url $token;

            # unpack token id
            $token_id = uuid_from_bin( substr $token_bin, 0, 16 )->str;

            $private_token_hash = sha3_512 substr $token_bin, 16;
        };

        # error decoding token
        return $self->_get_unauthenticated_descriptor if $@;

        $token_type = $TOKEN_TYPE_UNKNOWN;
    }

    return $self->authenticate_private( [ $token_id, $private_token_hash, $token_type ] );
}

sub authenticate_private ( $self, $private_token ) {
    my $auth;

    # private token is cached
    if ( $auth = $self->{_auth_cache_token}->{ $private_token->[$PRIVATE_TOKEN_ID] } ) {

        # private token is valid
        if ( $private_token->[$PRIVATE_TOKEN_HASH] eq $auth->{private_token}->[$PRIVATE_TOKEN_HASH] ) {

            # update last accessed time
            $auth->{last_accessed} = time;

            return $auth;
        }

        # private token is in cache, but hash is not valid
        else {
            return $self->_get_unauthenticated_descriptor($private_token);
        }
    }

    my $cv = P->cv;

    my $cache = $self->{_auth_cb_queue};

    push $cache->{ $private_token->[$PRIVATE_TOKEN_HASH] }->@*, $cv;

    return $cv->recv if $cache->{ $private_token->[$PRIVATE_TOKEN_HASH] }->@* > 1;

    # authenticate on backend
    my $res = $self->do_authenticate_private($private_token);

    # authentication error
    if ( !$res ) {

        # invalidate token
        $self->_invalidate_token( $private_token->[$PRIVATE_TOKEN_ID] );

        # return new unauthenticated auth object
        $auth = $self->_get_unauthenticated_descriptor($private_token);
    }

    # authenticated
    else {

        # create auth
        $auth = bless $res->{data}, 'Pcore::App::Auth::Descriptor';

        $auth->{app}              = $self->{app};
        $auth->{is_authenticated} = 1;
        $auth->{private_token}    = $private_token;
        $auth->{last_accessed}    = time;

        # store in cache
        $self->{_auth_cache_user}->{ $auth->{user_id} }->{ $private_token->[$PRIVATE_TOKEN_ID] } = 1;
        $self->{_auth_cache_token}->{ $private_token->[$PRIVATE_TOKEN_ID] } = $auth;
    }

    # call callbacks
    $cache = delete $cache->{ $private_token->[$PRIVATE_TOKEN_HASH] };

    while ( my $cb = shift $cache->@* ) {
        $cb->($auth);
    }

    return $cv->recv;
}

sub _get_unauthenticated_descriptor ( $self, $private_token = undef ) {
    return bless {
        app              => $self->{app},
        is_authenticated => 0,
        private_token    => $private_token,
      },
      'Pcore::App::Auth::Descriptor';
}

# CACHE INVALIDATE
sub _invalidate_user ( $self, $user_id ) {
    if ( my $user_tokens = delete $self->{_auth_cache_user}->{$user_id} ) {
        delete $self->{_auth_cache_token}->@{ keys $user_tokens->%* };
    }

    return;
}

sub _invalidate_token ( $self, $token_id ) {
    my $auth = delete $self->{_auth_cache_token}->{$token_id};

    if ( defined $auth ) {
        my $user_id = $auth->{user_id};

        delete $self->{_auth_cache_user}->{$user_id}->{$token_id};

        delete $self->{_auth_cache_user}->{$user_id} if !$self->{_auth_cache_user}->{$user_id}->%*;
    }

    return;
}

sub _invalidate_all ( $self ) {
    undef $self->{_auth_cache_user};

    undef $self->{_auth_cache_token};

    return;
}

sub _invalidate_expired_sessions ($self) {
    my $time = time - $SESSION_TIMEOUT;

    for my $auth ( values $self->{_auth_cache_token}->%* ) {
        if ( $auth->{private_token}->[$PRIVATE_TOKEN_TYPE] == $TOKEN_TYPE_SESSION && $auth->{last_accessed} < $time ) {
            $self->_invalidate_token( $auth->{private_token}->[$PRIVATE_TOKEN_ID] );
        }
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 131                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Auth

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 AUTHENTICATION METHODS

=head2 authentocate( $user_name, $token, $cb )

Performs user authentication and returns instance of Pcore::App::Auth::Drscriptor.

C<$user_name> can be undefined.

=head2 authentocate_private( $private_token, $cb )

Performs private token authentication and returns instance of Pcore::App::Auth::Drscriptor.

Private token structure is [ %token_type, $token_id, $token_hash ].

=head1 USER METHODS

=head2 create_user ( $user_name, $password, $enabled, $permissions, $cb )

Creates user and returns user id.

C<$permissions> - ArrayRef[ 'permission1', 'permission2', ... ]

=head2 get_users ( $cb )

Returns all users.

=head1 SEE ALSO

=cut
