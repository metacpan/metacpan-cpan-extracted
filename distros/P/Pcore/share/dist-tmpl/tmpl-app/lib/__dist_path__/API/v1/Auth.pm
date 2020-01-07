package <: $module_name ~ "::API::v1::Auth" :>;

use Pcore -const, -class, -sql, -res;
use Pcore::App::API qw[:TOKEN_TYPE :PRIVATE_TOKEN];
use <: $module_name ~ "::Const qw[:PERMS :AVATAR]" :>;
use Pcore::Util::Scalar qw[is_plain_hashref];
use Pcore::Util::Digest qw[sha256_bin hmac_sha256_hex];

extends qw[Pcore::App::API::Base];

const our $API_NAMESPACE_PERMS   => undef;
const our $TELEGRAM_AUTH_TIMEOUT => 30;

sub API_signin ( $self, $auth, $args ) {

    # authenticate
    if ( defined $args->{username} ) {

        # lowecase user name
        $args->{username} = lc $args->{username};

        my $user_id;

        # authenticate using telegram
        if ( $args->{username} eq 'telegram' && is_plain_hashref $args->{password} ) {
            $user_id = $self->_signin_telegram( $args->{password} );
        }

        # authenticate using username / password
        else {
            $user_id = $self->_signin_username( $args->{username}, $args->{password} );
        }

        return $user_id if !$user_id;

        $user_id = $user_id->{user_id};

        # create user session
        my $session = $self->{api}->user_session_create($user_id);

        # user session creation error
        return 500 if !$session;

        my $dbh = $self->{dbh};

        my $user = $dbh->selectrow( q[SELECT "id", "email", "has_avatar", "gravatar", "locale" FROM "user" WHERE "id" = ?], [$user_id] );

        # user session created
        return
          200,
          { settings         => $self->_get_app_settings($auth),
            token            => $session->{data}->{token},
            is_authenticated => 1,
            user_id          => $user_id,
            user_name        => $session->{data}->{user_name},
            locale           => $user->{data}->{locale},
            avatar           => $self->_get_avatar( $user->{data} ),
            permissions      => $session->{data}->{permissions},
          };
    }

    # not authenticated
    elsif ( !$auth ) {
        return 200,
          { settings         => $self->_get_app_settings($auth),
            is_authenticated => 0,
          };
    }

    # authenticated
    else {
        my $dbh = $self->{dbh};

        my $user = $dbh->selectrow( q[SELECT "id", "email", "has_avatar", "gravatar", "locale" FROM "user" WHERE "id" = ?], [ $auth->{user_id} ] );

        return 200,
          { settings         => $self->_get_app_settings($auth),
            is_authenticated => 1,
            user_id          => $auth->{user_id},
            user_name        => $auth->{user_name},
            locale           => $user->{data}->{locale},
            avatar           => $self->_get_avatar( $user->{data} ),
            permissions      => $auth->{permissions},
          };
    }
}

sub _get_app_settings ( $self, $auth ) {
    state $DEFAULT_LOCALE;

    state $locales = do {
        my $locales1 = $self->{app}->get_locales;

        if ($locales1) {
            if ( $locales1->%* == 0 ) {
                $DEFAULT_LOCALE = 'en';

                undef $locales1;
            }
            elsif ( $locales1->%* == 1 ) {
                $DEFAULT_LOCALE = ( keys $locales1->%* )[0];

                undef $locales1;
            }
        }

        $locales1;
    };

    state $version = $ENV->dist->version_string =~ s[\s([\S]+)\z][<br/>$1]smr;

    my $settings = $self->{api}->{settings};

    return {
        version           => $version,
        locales           => $locales,
        default_locale    => $DEFAULT_LOCALE // $self->{app}->get_default_locale($auth),
        telegram_bot_name => $settings->{telegram_signin_enabled} && $settings->{telegram_bot_key} ? $settings->{telegram_bot_name} : undef,
    };
}

sub _signin_username ( $self, $username, $password ) {

    # signin by email
    if ( index( $username, '@' ) > 0 ) {
        $username = lc $username;

        state $q1 = $self->{dbh}->prepare('SELECT "name" FROM "user" WHERE "email" = ? AND "enabled" = TRUE');

        my $res = $self->{dbh}->selectrow( $q1, [$username] );

        return $res if !$res;

        return res 404 if !$res->{data};

        $username = $res->{data}->{name};
    }

    my $auth = $self->{api}->authenticate( [ $username, $password ] );

    # authentication error
    return res 401 if !$auth;

    return res 200, user_id => $auth->{user_id};
}

sub _signin_telegram ( $self, $telegram ) {
    my $settings = $self->{api}->{settings};

    # telegram signin is disabled
    return res 401 if !$settings->{telegram_signin_enabled} || !$settings->{telegram_bot_name} || !$settings->{telegram_bot_key};

    # telegram authentication is expired
    return res 401 if $telegram->{auth_date} + $TELEGRAM_AUTH_TIMEOUT < time;

    my $dbh = $self->{dbh};

    # find user id by telegram username
    state $q1 = $dbh->prepare(q[SELECT "id" FROM "user" WHERE "enabled" = TRUE AND "telegram_name" = ?]);

    my $user_id = $dbh->selectrow( $q1, [ $telegram->{username} ] );

    return res 401 if !$user_id->{data};

    $user_id = $user_id->{data}->{id};

    my $hash = delete $telegram->{hash};

    # validate telegram hash
    my $data_check_string = join "\n", map {"$_=$telegram->{$_}"} sort keys $telegram->%*;

    return res 401 if hmac_sha256_hex( $data_check_string, sha256_bin $settings->{telegram_bot_key} ) ne $hash;

    return res 200, user_id => $user_id;
}

# TODO
sub API_confirm_email ( $self, $auth, $token ) {
    return 400 if !$token;

    my $dbh = $self->{dbh};

    $token = $dbh->selectrow( q[SELECT * FROM "user_action_token" WHERE "token" = ? AND "token_type" = ?], [ $token, $TOKEN_TYPE_EMAIL_CONFIRM ] );

    # token was not found
    return [ 400, 'Your token is invalid' ] if !$token->{data};

    my $user = $dbh->selectrow( q[SELECT "id", "email", "enabled", "email_confirmed" FROM "user" WHERE "id" = ?], [ $token->{data}->{user_id} ] );

    # user was not found or disabled or email was changed
    return [ 400, 'User was not found' ] if !$user->{data}->{enabled} || $user->{data}->{email} ne $token->{data}->{email};

    # set email confirmed
    if ( !$user->{data}->{email_confirmed} ) {
        my $res = $dbh->do( q[UPDATE "user" SET "email_confirmed" = TRUE WHERE "id" = ?], [ $token->{data}->{user_id} ] );

        return $res if !$res;
    }

    # remove token
    my $res = $dbh->do( q[DELETE FROM "user_action_token" WHERE "user_id" = ? AND "token_type" = ?], [ $user->{data}->{id}, $TOKEN_TYPE_EMAIL_CONFIRM ] );

    return $res if !$res;

    return 200;
}

sub API_recover_password ( $self, $auth, $user_id ) {
    my $token = $self->{api}->user_action_token_create( $user_id, $TOKEN_TYPE_PASSWORD_RECOVERY );

    return $token if !$token;

    my $res = $self->_send_password_recovery_email( $token->{data}->{email}, $token->{data}->{token} );

    return $res;
}

sub API_change_password ( $self, $auth, $token, $password ) {
    return 400 if !$token;

    $token = $self->{api}->user_action_token_verify( $token, $TOKEN_TYPE_PASSWORD_RECOVERY );

    # token verification error
    return $token if !$token;

    my ( $res, $dbh ) = $self->{dbh}->get_dbh;

    # unable to get dbh
    return $res if !$res;

    $res = $dbh->begin_work;

    # unable to start transaction
    return $res if !$res;

    state $on_finish = sub ( $dbh, $res ) {
        if ( !$res ) {
            my $res1 = $dbh->rollback;
        }
        else {
            my $res1 = $dbh->commit;

            # error committing transaction
            return $res1 if !$res1;
        }

        return $res;
    };

    $res = $self->{api}->user_set_password( $token->{data}->{user_id}, $password, $dbh );

    # set password error
    return $on_finish->( $dbh, $res ) if !$res;

    $res = $self->{api}->user_action_token_remove( $TOKEN_TYPE_PASSWORD_RECOVERY, $token->{data}->{email} );

    # error
    return $on_finish->( $dbh, $res ) if !$res;

    # set email confirmed
    $res = $self->{dbh}->do( 'UPDATE "user" SET "email_confirmed" = TRUE WHERE "id" = ?', [ $token->{data}->{user_id} ] );

    return $on_finish->( $dbh, res 200 );
}

# TODO
sub API_signup ( $self, $auth, $args ) {

    #     my $dbh = $self->{dbh};

    #     my $permissions = ['user'];

    #     # lowecase user name
    #     $args->{username} = lc $args->{username};

    #     my $res = $self->{api}->user_create( $args->{username}, $args->{password}, 1, $permissions );

    #     if ( !$res ) {
    #         return $res;
    #     }
    #     else {
    #         $res = $dbh->do(
    #             'INSERT INTO "user" ("id", "name", "enabled", "email") VALUES (?, ?, ?, ?)',
    #             [    #
    #                 $res->{data}->{id},
    #                 $args->{username},
    #                 SQL_BOOL 1,
    #                 $args->{username},
    #             ]
    #         );

    #         return $res;
    #     }

    return 400;
}

# EMAIL
sub _send_confirmation_email ( $self, $to, $token ) {
    my $domain = $self->{api}->{settings}->{domain};

    my $params = {    #
        url => qq[https://$domain/#!confirm-email/$token],
    };

    state $tmpl = P->tmpl;

    return $self->{app}->{util}->sendmail( $to, undef, 'Confirm your email', $tmpl->( 'email/confirm-email.txt', $params ) );
}

sub _send_password_recovery_email ( $self, $to, $token ) {
    my $domain = $self->{api}->{settings}->{domain};

    my $params = {    #
        url => qq[https://$domain/#!change-password/$token],
    };

    state $tmpl = P->tmpl;

    return $self->{app}->{util}->sendmail( $to, undef, 'Change password', $tmpl->( 'email/recover-password.txt', $params ) );
}

# sub API_check_session : Perms($PERMS_ANY_AUTHENTICATED_USER) ( $self, $auth ) {
#     return 200;
# }

sub _get_avatar ( $self, $user ) {
    if ( $user->{has_avatar} ) {
        return $self->{app}->{cdn}->('/user/') . "/$user->{guid}/avatar.png";
    }
    elsif ( $user->{gravatar} ) {
        return "https://s.gravatar.com/avatar/$user->{gravatar}?d=$DEFAULT_GRAVATAR_IMAGE";
    }
    else {
        return $DEFAULT_AVATAR;
    }
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
## |    3 | 299                  | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_send_confirmation_email' declared  |
## |      |                      | but not used                                                                                                   |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 341                  | Documentation::RequirePackageMatchesPodName - Pod NAME on line 345 does not match the package declaration      |
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
