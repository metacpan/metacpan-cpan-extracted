package Pcore::App::API::Backend;

use Pcore -role, -const, -res;
use Pcore::App::API::Const qw[:INVALIDATE_TYPE :TOKEN_TYPE :PRIVATE_TOKEN];
use Pcore::Util::Scalar qw[is_plain_arrayref];
use Pcore::Util::Data qw[from_b64u];
use Pcore::Util::Digest qw[sha3_512_bin];
use Pcore::Util::Text qw[encode_utf8];
use Pcore::Util::UUID qw[uuid_from_bin];

requires qw[init do_authenticate_private];

has app => ( required => 1 );
has api => ( required => 1 );

has _auth_cb_queue            => ( sub { {} }, init_arg => undef );    # HashRef
has _auth_cache_user          => ( init_arg             => undef );    # HashRef, user_id => { user_token_id }
has _auth_cache_token         => ( init_arg             => undef );    # HashRef, user_token_id => auth_descriptor
has _auth_cache_cleanup_timer => ( init_arg             => undef );    # InstanceOf['AE::timer']

const our $AUTH_CACHE_CLEANUP_TIMEOUT => 60 * 60 * 12;                 # remove sessions tokens, that are older than 12 hours

# INIT
around init => sub ( $orig, $self ) {

    # setup events listeners
    P->bind_events(
        'app.api.auth.invalidate',
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
    $self->{_auth_cache_cleanup_timer} = AE::timer $AUTH_CACHE_CLEANUP_TIMEOUT, $AUTH_CACHE_CLEANUP_TIMEOUT, sub {
        $self->_auth_cache_cleanup;

        return;
    };

    my $res = $self->$orig;

    return $res;
};

# AUTHENTICATE
sub authenticate ( $self, $token = undef ) {

    # no auth token provided
    return $self->_get_unauthenticated_descriptor if !defined $token;

    my $private_token;

    # authenticate user password
    if ( is_plain_arrayref $token) {

        # $token is private token
        if ( $token->@* == 3 ) {
            $private_token = $token;
        }

        # $token is user / pass array
        else {
            my ( $token_type, $token_id, $private_token_hash );

            # lowercase user name
            $token->[0] = lc $token->[0];

            # generate private token hash
            $private_token_hash = eval { sha3_512_bin encode_utf8( $token->[1] ) . encode_utf8 $token->[0] };

            $private_token = [ $token->[0], $private_token_hash, $TOKEN_TYPE_PASSWORD ] if !$@;
        }
    }

    # authenticate token
    else {
        $private_token = $self->_unpack_token($token);
    }

    # error decoding token
    return $self->_get_unauthenticated_descriptor if !$private_token;

    return $self->authenticate_private($private_token);
}

sub _unpack_token ( $self, $token ) {
    my ( $token_id, $token_type, $private_token_hash );

    # decode token
    eval {
        my $token_bin = from_b64u $token;

        # unpack token id
        $token_id = uuid_from_bin( substr $token_bin, 0, 16 )->str;

        die if length $token_bin < 16;

        $token_type = unpack 'C', substr $token_bin, 16, 1;

        $private_token_hash = sha3_512_bin substr $token_bin, 17;
    };

    # error decoding token
    return if $@;

    return [ $token_id, $private_token_hash, $token_type ];
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
        $auth = bless $res->{data}, 'Pcore::App::API::Auth';

        $auth->{api}              = $self->{api};
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
        api              => $self->{api},
        is_authenticated => 0,
        private_token    => $private_token,
      },
      'Pcore::App::API::Auth';
}

# AUTH CACHE INVALIDATE
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

sub _auth_cache_cleanup ($self) {
    my $time = time - $AUTH_CACHE_CLEANUP_TIMEOUT;

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
## |    3 | 101                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
