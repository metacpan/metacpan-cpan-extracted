package <: $module_name ~ "::API::v1::Auth" :>;

use Pcore -class, -const;
use Pcore::App::API qw[:CONST];
use <: $module_name ~ "::Const qw[:CONST]" :>;

extends qw[Pcore::App::API::Base];

const our $API_NAMESPACE_PERMISSIONS => undef;

sub API_app_init : Permissions('*') ( $self, $req, $data = undef ) {
    return $req->( 200, { user_name => $req->{auth} ? ( $req->{auth}->{user_name} ) : undef, } );
}

sub API_signin : Permissions('*') ( $self, $req, $data ) {
    my $auth = $self->{app}->{auth}->authenticate( [ $data->{user_name}, $data->{password} ] );

    # authentication error
    return $req->(401) if !$auth;

    # create user session
    my $session = $self->{app}->{auth}->user_session_create( $auth->{user_id} );

    # user session creation error
    return $req->(500) if !$session;

    # user session created
    return $req->( 200, { user_name => $data->{user_name}, token => $session->{data}->{token} } );
}

sub API_signout : Permissions('*') ( $self, $req, @ ) {

    # request is authenticated from the session token
    if ( $req->{auth}->{private_token}->[$PRIVATE_TOKEN_TYPE] && $req->{auth}->{private_token}->[$PRIVATE_TOKEN_TYPE] == $TOKEN_TYPE_SESSION ) {

        # remove user session
        return $req->( $self->{app}->{auth}->remove_user_session( $req->{auth}->{private_token}->[$PRIVATE_TOKEN_ID] ) );
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
## |    1 | 58                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 62 does not match the package declaration       |
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
