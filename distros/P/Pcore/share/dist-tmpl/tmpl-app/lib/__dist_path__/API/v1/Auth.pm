package <: $module_name ~ "::API::v1::Auth" :>;

use Pcore -class;
use Pcore::App::API qw[:CONST];
use <: $module_name ~ "::Const qw[:CONST]" :>;

extends qw[Pcore::App::API::Role];

our $API_MAP = {    #
    app_init => { permissions => undef, desc => 'get ext app init settings' },
    signin   => { permissions => undef, desc => 'signin user' },
    signout  => { permissions => q[*],  desc => 'signout user' },
};

sub _build_api_map ($self) {
    return $API_MAP;
}

sub API_app_init ( $self, $req, $data = undef ) {
    return $req->( 200, { user_name => $req->{auth} ? ( $req->{auth}->{user_name} ) : undef, } );
}

sub API_signin ( $self, $req, $data ) {
    $self->{app}->{api}->authenticate(
        [ $data->{user_name}, $data->{password} ],
        Coro::unblock_sub sub ($auth) {

            # authentication error
            return $req->(401) if !$auth;

            # create user session
            my $session = $self->{app}->{api}->create_user_session( $auth->{user_id} );

            # user session creation error
            return $req->(500) if !$session;

            # user session created
            return $req->( 200, { user_name => $data->{user_name}, token => $session->{data}->{token} } );
        }
    );

    return;
}

sub API_signout ( $self, $req, @ ) {

    # request is authenticated from session token
    if ( $req->{auth}->{private_token}->[0] && $req->{auth}->{private_token}->[0] == $TOKEN_TYPE_USER_SESSION ) {

        # remove user session
        return $req->( $self->{app}->{api}->remove_user_session( $req->{auth}->{private_token}->[1] ) );
    }

    # not a session token
    return $req->(400);
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
## |    1 | 72                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 76 does not match the package declaration       |
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
