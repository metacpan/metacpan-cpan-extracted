package Pcore::App::API::Backend::Local::sqlite::AppInstance;

use Pcore -role, -result;
use Pcore::App::API qw[:CONST];
use Pcore::Util::Text qw[encode_utf8];

# TODO salt = app_id
# TODO return result hash
sub _auth_app_instance_token ( $self, $source_app_instance_id, $private_token, $cb ) {
    state $sql1 = <<'SQL';
        SELECT
            api_app_instance.app_id,
            api_app_instance.hash,
            api_app.enabled AS app_enabled,
            api_app_instance.enabled AS app_instance_enabled
        FROM
            api_app,
            api_app_instance
        WHERE
            api_app_instance.app_id = api_app.id
            AND api_app_instance.id = ?
SQL

    state $sql2 = <<'SQL';
        SELECT
            api_app_role.name AS source_app_role_name
        FROM
            api_app_instance,
            api_app_role,
            api_app_permissions
        WHERE
            api_app_instance.id = ?                              --- source app_instance_id
            AND api_app_role.app_id = api_app_instance.app_id    --- link source_app_instance_role to source_app
            AND api_app_role.enabled = 1                         --- source_app_role must be enabled

            AND api_app_permissions.role_id = api_app_role.id    --- link permission to role
            AND api_app_permissions.enabled = 1                  --- permission must be enabled
            AND api_app_permissions.app_id = ?                   --- link permission to target app id
SQL

    # get app instance
    my $res = $self->dbh->selectrow( $sql1, [ $private_token->[1] ] );

    # app instance not found
    if ( !$res ) {
        $cb->( result [ 404, 'App instance not found' ] );

        return;
    }

    # verify token
    $self->_verify_token_hash(
        $private_token->[2],
        $res->{hash},
        encode_utf8( $res->{app_id} ),
        sub ($status) {

            # token is not valid
            if ( !$status ) {
                $cb->($status);
            }

            # token is valid
            else {
                my $auth = {
                    private_token => $private_token,

                    is_user   => 0,
                    is_root   => undef,
                    user_id   => undef,
                    user_name => undef,

                    is_app          => 0,
                    app_id          => $res->{app_id},
                    app_instance_id => $private_token->[1],

                    enabled => $res->{app_enabled} && $res->{app_instance_enabled},

                    permissions => {},
                };

                my $tags = {
                    app_id          => $res->{app_id},
                    app_instance_id => $private_token->[1],
                };

                # get permissions
                if ( my $roles = $self->dbh->selectall( $sql2, [ $source_app_instance_id, $res->{app_id} ] ) ) {
                    for my $row ( $roles->@* ) {
                        $auth->{permissions}->{ $row->{source_app_role_name} } = 1;
                    }
                }

                $cb->( result 200, auth => $auth, tags => $tags );
            }

            return;
        }
    );

    return;
}

sub get_app_instance ( $self, $app_instance_id, $cb ) {
    if ( my $app_instance = $self->dbh->selectrow( q[SELECT * FROM api_app_instance WHERE id = ?], [$app_instance_id] ) ) {
        delete $app_instance->{hash};

        $cb->( result 200, $app_instance );
    }
    else {
        $cb->( result [ 404, 'App instance not found' ] );
    }

    return;
}

sub create_app_instance ( $self, $app_id, $app_instance_host, $app_instance_version, $cb ) {
    $self->get_app(
        $app_id,
        sub ($app) {
            if ( !$app ) {
                $cb->($app);
            }
            else {
                $self->_generate_token(
                    $TOKEN_TYPE_APP_INSTANCE_TOKEN,
                    $app->{data}->{id},
                    sub ( $token ) {

                        # app instance token generation error
                        if ( !$token ) {
                            $cb->($token);
                        }

                        # app instance token generated
                        else {

                            my $created = $self->dbh->do( q[INSERT OR IGNORE INTO api_app_instance (id, app_id, version, host, created_ts, hash) VALUES (?, ?, ?, ?, ?, ?)], [ $token->{data}->{id}, $app->{data}->{id}, $app_instance_version, $app_instance_host, time, $token->{data}->{hash} ] );

                            if ( !$created ) {
                                $cb->( result [ 400, 'App instance creation error' ] );
                            }
                            else {
                                $self->get_app_instance(
                                    $token->{data}->{id},
                                    sub ($app_instance) {
                                        if ($app_instance) {
                                            $app_instance->{data}->{token} = $token->{data}->{token};
                                        }

                                        $cb->($app_instance);

                                        return;
                                    }
                                );
                            }
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

sub set_app_instance_token ( $self, $app_instance_id, $cb ) {
    $self->_generate_app_instance_token(
        $app_instance_id,
        sub ( $token ) {

            # app instance token generation error
            if ( !$token ) {
                $cb->($token);
            }

            # app instance token generated
            else {

                # set app instance token
                if ( $self->dbh->do( q[UPDATE api_app_instance SET hash = ? WHERE id = ?], [ $token->{data}->{hash}, $app_instance_id ] ) ) {
                    $cb->( result 200, $token->{data}->{token} );
                }

                # set token error
                else {
                    $cb->( result [ 500, 'Error creation app instance token' ] );
                }
            }

            return;
        }
    );

    return;
}

sub update_app_instance ( $self, $app_instance_id, $app_instance_version, $cb ) {
    my $updated = $self->dbh->do( q[UPDATE OR IGNORE api_app_instance SET version = ?, last_connected_ts = ? WHERE id = ?], [ $app_instance_version, time, $app_instance_id ] );

    if ( !$updated ) {
        $cb->( result [ 400, 'App instance update error' ] );
    }
    else {
        $cb->( result 200 );
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
## |    3 | 9, 117, 202          | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 9                    | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_auth_app_instance_token' declared  |
## |      |                      | but not used                                                                                                   |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::sqlite::AppInstance

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
