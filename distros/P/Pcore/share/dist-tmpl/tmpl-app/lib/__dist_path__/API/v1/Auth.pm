package <: $module_name ~ "::API::v1::Auth" :>;

use Pcore -class;
use Pcore::App::API qw[:CONST];
use <: $module_name ~ "::Const qw[:CONST]" :>;
use Pcore::Util::Random qw[random_bytes_hex];

with qw[Pcore::App::API::Role];

our $API_MAP = {
    app_init                 => { permissions => undef,     desc => 'init ExtJS application' },
    signin                   => { permissions => undef,     desc => 'sign in' },
    signout                  => { permissions => q[*],      desc => 'sign out' },
    send_password_email      => { permissions => undef,     desc => 'send password change email' },
    confirm_email_by_token   => { permissions => undef,     desc => 'confirm email using token' },
    change_password_by_token => { permissions => undef,     desc => 'change password using token' },
    change_password_for_user => { permissions => ['admin'], desc => 'change password for any user' },
};

sub _build_api_map ($self) {
    return $API_MAP;
}

sub API_app_init ( $self, $req, $args = undef ) {
    $req->(
        200,
        {   user_name => $req->{auth} ? ( $req->{auth}->{user_name} ) : undef,
            recaptcha_site_key => $self->{app}->recaptcha_api ? $self->{app}->{settings}->{recaptcha_site_key} : undef,
        }
    );

    return;
}

sub API_signin ( $self, $req, $data ) {
    my $signin = sub {
        $self->{app}->{api}->authenticate(
            $data->{user_name},
            $data->{password},
            sub ($auth) {

                # authentication error
                if ( !$auth ) {
                    $req->(401);
                }

                # authenticated
                else {
                    my $create_sess = sub {

                        # create user session
                        $self->{app}->{api}->create_user_session(
                            $auth->{user_id},
                            '127.0.0.1',
                            'user-agent',
                            sub ($session) {

                                # user session creation error
                                if ( !$session ) {
                                    $req->(401);
                                }

                                # user session created
                                else {
                                    $req->( 200, { user_name => $data->{user_name}, token => $session->{data}->{token} } );
                                }

                                return;
                            }
                        );

                        return;
                    };

                    if ( $auth->{is_root} ) {
                        $create_sess->();
                    }

                    # check, that user is staff
                    else {
                        $self->{app}->{dbh}->selectrow(
                            'SELECT "id" FROM "user" WHERE "email" = ?',
                            [ $auth->{user_id} ],
                            sub ( $dbh, $res, $data ) {
                                if ( !$data ) {
                                    $req->(401);
                                }
                                else {
                                    $create_sess->();
                                }

                                return;
                            }
                        );
                    }
                }

                return;
            }
        );

        return;
    };

    my $recaptcha_api = $self->{app}->recaptcha_api;

    if ( !$recaptcha_api ) {
        $signin->();
    }
    elsif ( !$data->{recaptcha} ) {
        $req->( [ 400, 'reCaptcha is required' ] );
    }
    else {

        # verify reCaptcha
        $recaptcha_api->verify(
            $data->{recaptcha},
            undef,
            sub ($res) {

                # reCaptcha verification error
                if ( !$res ) {
                    $req->( [ 400, 'reCaptcha error' ] );
                }

                # reCaptcha OK
                else {
                    $signin->();
                }

                return;
            }
        );
    }

    return;
}

sub API_signout ( $self, $req, @ ) {

    # request is authenticated from session token
    if ( $req->{auth}->{private_token}->[0] && $req->{auth}->{private_token}->[0] == $TOKEN_TYPE_USER_SESSION ) {

        # remove user session
        $self->{app}->{api}->remove_user_session(
            $req->{auth}->{private_token}->[1],
            sub ($res) {

                # session was not removed
                if ( !$res ) {
                    $req->(500);
                }

                # session removed
                else {
                    $req->(200);
                }

                return;
            }
        );
    }

    # not a session token
    else {
        $req->(400);
    }

    return;
}

sub API_send_password_email ( $self, $req, $args ) {
    my $send_mail = sub {
        $self->{app}->{dbh}->selectrow(
            q[SELECT "id", "email" FROM "user" WHERE "name" = $1],
            [ $args->{user_name} ],
            sub ( $dbh, $status, $user ) {
                if ( !$user ) {
                    $req->( [ 500, q[User wasn't found] ] );
                }
                else {
                    if ( !$user->{email} ) {
                        $req->( [ 500, q[User has no email defined] ] );
                    }
                    else {
                        my $token = random_bytes_hex(32);

                        # create user change password token
                        $dbh->do(
                            q[INSERT INTO "user_action_token" ("token", "user_id", "token_type", "email") VALUES ($1, $2, $3, $4)],
                            [ $token, $user->{id}, $USER_ACTION_TOKEN_PASSWORD, $user->{email} ],
                            sub ( $dbh, $status, $data ) {
                                if ( !$status ) {
                                    $req->(500);
                                }
                                else {

                                    # send email
                                    $self->{app}->sendmail(
                                        $user->{email},
                                        undef,
                                        'Change password link',
                                        "https://billing.lcom.net.ua/change-password/?id=$token",
                                        sub ($res) {
                                            if ( !$res ) {
                                                $req->($res);
                                            }
                                            else {
                                                $req->( [ 200, 'Password recovery email was sent' ] );
                                            }
                                        }
                                    );
                                }

                                return;
                            }
                        );
                    }
                }
            }
        );

        return;
    };

    my $recaptcha_api = $self->{app}->recaptcha_api;

    if ( !$recaptcha_api ) {
        $send_mail->();
    }
    elsif ( !$args->{recaptcha} ) {
        $req->( [ 400, 'reCaptcha is required' ] );
    }
    else {

        # verify reCaptcha
        $recaptcha_api->verify(
            $args->{recaptcha},
            undef,
            sub ($res) {

                # reCaptcha verification error
                if ( !$res ) {
                    $req->( [ 400, 'reCaptcha error' ] );
                }

                # reCaptcha OK
                else {
                    $send_mail->();
                }

                return;
            }
        );
    }

    return;
}

sub API_confirm_email_by_token ( $self, $req, $action_token ) {
    $self->{app}->{dbh}->selectrow(
        q[SELECT * FROM "user_action_token" WHERE "token" = $1],
        [$action_token],
        sub ( $dbh, $status, $token ) {

            # token was not found
            if ( !$status || !$token ) {
                $req->( [ 500, 'Token was not found' ] );
            }
            else {

                # delete all user email confirmation tokens
                $dbh->do(
                    q[DELETE FROM "user_action_token" WHERE "user_id" = $1 AND "token_type" = $2],
                    [ $token->{user_id}, $USER_ACTION_TOKEN_EMAIL ],
                    sub ( $dbh, $status, $data ) {
                        if ( !$status ) {
                            $req->( [ 500, 'Error processing token' ] );
                        }
                        else {

                            # mark user email as confirmed
                            $dbh->do(
                                q[UPDATE "user" SET "email_confirmed" = TRUE WHERE "id" = $1],
                                [ $token->{user_id} ],
                                sub ( $dbh, $status, $data ) {
                                    $req->( $status && $status->{rows} ? 200 : 500 );

                                    return;
                                }
                            );
                        }

                        return;
                    }
                );
            }

            return;
        }
    );

    return;
}

sub API_change_password_by_token ( $self, $req, $args ) {
    $self->{app}->{dbh}->selectrow(
        q[SELECT * FROM "user_action_token" WHERE "token" = $1],
        [ $args->{token} ],
        sub ( $dbh, $status, $token ) {

            # token was not found
            if ( !$status || !$token ) {
                $req->( [ 500, 'Token was not found' ] );
            }
            else {

                # delete all user change password tokens
                $dbh->do(
                    q[DELETE FROM "user_action_token" WHERE "user_id" = $1 AND "token_type" = $2],
                    [ $token->{user_id}, $USER_ACTION_TOKEN_PASSWORD ],
                    sub ( $dbh, $status, $data ) {
                        if ( !$status ) {
                            $req->( [ 500, 'Error processing token' ] );
                        }
                        else {

                            # mark user email as confirmed
                            $dbh->do(
                                q[UPDATE "user" SET "email_confirmed" = TRUE WHERE "id" = $1],
                                [ $token->{user_id} ],
                                sub ( $dbh, $status, $data ) {
                                    if ( !$status ) {
                                        $req->( [ 500, 'Error updating user data' ] );
                                    }
                                    else {

                                        # change user password
                                        $self->{app}->{api}->set_user_password(
                                            $token->{user_id},
                                            $args->{password},
                                            sub ($res) {
                                                $req->( $res ? 200 : [ 500, 'Password was not set' ] );

                                                return;
                                            }
                                        );
                                    }

                                    return;
                                }
                            );
                        }

                        return;
                    }
                );
            }

            return;
        }
    );

    return;
}

# TODO change password for any user
# TODO root password can be changed only by root user
sub API_change_password_for_user ( $self, $req, $args ) {
    return;
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
## |    1 | 175, 190, 262, 274,  | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## |      | 284, 308, 320, 330   |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 390                  | Documentation::RequirePackageMatchesPodName - Pod NAME on line 394 does not match the package declaration      |
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
