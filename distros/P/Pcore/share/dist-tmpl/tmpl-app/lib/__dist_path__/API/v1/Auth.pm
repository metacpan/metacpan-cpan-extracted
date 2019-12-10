package <: $module_name ~ "::API::v1::Auth" :>;

use Pcore -class, -const;
use Pcore::App::API qw[:CONST];
use <: $module_name ~ "::Const qw[:CONST]" :>;

extends qw[Pcore::App::API::Base];

const our $API_NAMESPACE_PERMISSIONS => undef;

sub API_app_init : Permissions('*') ( $self, $auth, $data = undef ) {
    return 200, { user_name => $auth ? ( $auth->{user_name} ) : undef };
}

sub API_signin : Permissions('*') ( $self, $auth, $data ) {
    my $user_auth = $self->{app}->{auth}->authenticate( [ $data->{user_name}, $data->{password} ] );

    # authentication error
    return 401 if !$user_auth;

    # create user session
    my $session = $self->{app}->{auth}->user_session_create( $user_auth->{user_id} );

    # user session creation error
    return 500 if !$session;

    # user session created
    return 200, { user_name => $data->{user_name}, token => $session->{data}->{token} };
}

sub API_signout : Permissions('*') ( $self, $auth, @ ) {

    # request is authenticated from the session token
    if ( $auth->{private_token}->[$PRIVATE_TOKEN_TYPE] && $auth->{private_token}->[$PRIVATE_TOKEN_TYPE] == $TOKEN_TYPE_SESSION ) {

        # remove user session
        return $self->{app}->{auth}->remove_user_session( $auth->{private_token}->[$PRIVATE_TOKEN_ID] );
    }

    # not a session token
    return 400;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1, 5                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 46                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 50 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::API::v1::Auth" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
