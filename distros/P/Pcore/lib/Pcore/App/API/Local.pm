package Pcore::App::API::Local;

use Pcore -const, -role, -res, -sql;
use Pcore::App::API qw[:CONST];
use Pcore::Util::Data qw[to_b64_url];
use Pcore::Util::Digest qw[sha3_512];
use Pcore::Util::Text qw[encode_utf8];
use Pcore::Util::UUID qw[uuid_v4 looks_like_uuid];

with qw[Pcore::App::API];

has dbh              => ();        # ( isa => InstanceOf ['Pcore::Handle::DBI'],         init_arg => undef );
has _hash_cache      => ();        # ( isa => InstanceOf ['Pcore::Util::Hash::RandKey'], init_arg => undef );
has _hash_cache_size => 10_000;    # isa => PositiveInt;

sub init ( $self ) {
    $self->{_hash_cache} = P->hash->limited( $self->{_hash_cache_size} );

    # create DBH
    $self->{dbh} = P->handle( $self->{app}->{app_cfg}->{api}->{connect} );

    # update schema
    $self->_db_add_schema_patch( $self->{dbh} );

    print 'Upgrading API DB schema ... ';

    say my $res = $self->{dbh}->upgrade_schema;

    return $res unless $res;

    my $roles = do {
        no strict qw[refs];

        ${ ref( $self->{app} ) . '::API_ROLES' };
    };

    # add api roles
    ( $res = $self->_db_add_roles( $self->{dbh}, $roles ) ) || return $res;

    # run hash RPC
    print 'Starting API RPC ... ';

    say $self->{app}->{node}->run_node(
        {   type      => 'Pcore::App::API::RPC::Hash',
            workers   => $self->{app}->{app_cfg}->{api}->{rpc}->{workers},
            buildargs => $self->{app}->{app_cfg}->{api}->{rpc}->{argon},
        },
    );

    $self->{app}->{node}->wait_for('Pcore::App::API::RPC::Hash');

    print 'Creating root user ... ';

    my $root_password = P->random->bytes_hex(32);

    $res = $self->create_user( 'root', $root_password, 1, undef );

    say $res . ( $res ? ", password: $root_password" : q[] );

    return res 200;
}

# AUTHENTICATE
sub do_authenticate_private ( $self, $private_token ) {
    if ( $private_token->[0] == $TOKEN_TYPE_USER_PASSWORD ) {
        return $self->_auth_user_password($private_token);
    }
    elsif ( $private_token->[0] == $TOKEN_TYPE_USER_TOKEN ) {
        return $self->_auth_user_token($private_token);
    }
    elsif ( $private_token->[0] == $TOKEN_TYPE_USER_SESSION ) {
        return $self->_auth_user_token($private_token);
    }
    else {
        return res [ 400, 'Invalid token type' ];
    }
}

# TOKENS / HASH GENERATORS
sub validate_name ( $self, $name ) {

    # name looks like UUID string
    return if looks_like_uuid $name;

    return if $name =~ /[^[:alnum:]_@.-]/smi;

    return 1;
}

sub _verify_token_hash ( $self, $private_token_hash, $hash ) {
    my $cache_id = "$hash/$private_token_hash";

    if ( exists $self->{_hash_cache}->{$cache_id} ) {
        return $self->{_hash_cache}->{$cache_id};
    }
    else {
        my $res = $self->{app}->{node}->rpc_call( 'Pcore::App::API::RPC::Hash', 'verify_hash', $private_token_hash, $hash );

        return $self->{_hash_cache}->{$cache_id} = $res->{data} ? res 200 : res [ 400, 'Invalid token' ];
    }
}

sub _generate_user_password_hash ( $self, $user_name_utf8, $user_password_utf8 ) {
    my $user_name_bin = encode_utf8 $user_name_utf8;

    my $user_password_bin = encode_utf8 $user_password_utf8;

    my $private_token_hash = sha3_512 $user_password_bin . $user_name_bin;

    my $res = $self->{app}->{node}->rpc_call( 'Pcore::App::API::RPC::Hash', 'create_hash', $private_token_hash );

    return $res if !$res;

    return res 200, { hash => $res->{data} };
}

sub _generate_token ( $self, $token_type ) {
    my $token_id = uuid_v4;

    my $public_token = to_b64_url pack( 'C', $token_type ) . $token_id->bin . P->random->bytes(32);

    my $private_token_hash = sha3_512 $public_token;

    my $res = $self->{app}->{node}->rpc_call( 'Pcore::App::API::RPC::Hash', 'create_hash', $private_token_hash );

    return $res if !$res;

    return res 200, { id => $token_id->str, token => $public_token, hash => $res->{data} };
}

sub _return_auth ( $self, $private_token, $user_id, $user_name ) {
    my $auth = {
        private_token => $private_token,

        is_root   => $user_name eq 'root' ? 1 : 0,
        user_id   => $user_id,
        user_name => $user_name,

        permissions => {},
    };

    # is a root user
    return res 200, $auth if $auth->{is_root};

    if ( $private_token->[0] == $TOKEN_TYPE_USER_TOKEN ) {
        my $res = $self->_db_get_user_token_permissions( $self->{dbh}, $private_token->[1] );

        return $res if !$res;

        $auth->{permissions} = { map { $_->{role_name} => 1 } $res->{data}->@* };

        return res 200, $auth;
    }
    else {
        my $res = $self->_db_get_user_permissions( $self->{dbh}, $user_id );

        return $res if !$res;

        $auth->{permissions} = { map { $_->{role_name} => 1 } $res->{data}->@* };

        return res 200, $auth;
    }
}

# USER
sub _auth_user_password ( $self, $private_token ) {

    # get user
    my $user = $self->{dbh}->selectrow( q[SELECT "id", "hash", "enabled" FROM "api_user" WHERE "name" = ?], [ $private_token->[1] ] );

    # user not found
    return res [ 404, 'User not found' ] if !$user->{data};

    # user is disabled
    return res [ 404, 'User is disabled' ] if !$user->{data}->{enabled};

    # verify token
    my $status = $self->_verify_token_hash( $private_token->[2], $user->{data}->{hash} );

    # token is invalid
    return $status if !$status;

    # token is valid
    return $self->_return_auth( $private_token, $user->{data}->{id}, $private_token->[1] );
}

sub create_user ( $self, $user_name, $password, $enabled, $permissions ) {

    # validate user name
    return res [ 400, 'User name is not valid' ] if !$self->validate_name($user_name);

    state $on_finish = sub ( $dbh, $res ) {
        if ( !$res ) {
            my $res1 = $dbh->rollback;

            return $res;
        }
        else {
            my $res1 = $dbh->commit;

            # error committing transaction
            return $res1 if !$res1;

            return $res;
        }

        return;
    };

    # start transaction
    my ( $dbh, $res ) = $self->{dbh}->begin_work;

    # failed to start transaction
    return $res if !$res;

    # check, that user is not exists
    my $user = $self->_db_get_user( $dbh, $user_name );

    # user already exists
    return $on_finish->( $dbh, res [ 400, 'User name already exists' ] ) if $user;

    # generate user password hash
    $res = $self->_generate_user_password_hash( $user_name, $password );

    # error generating hash
    return $on_finish->( $dbh, res 500 ) if !$res;

    # insert user
    $user = $self->_db_create_user( $dbh, $user_name, $res->{data}->{hash}, $enabled );

    # failed to insert user
    return $on_finish->( $dbh, res 500 ) if !$user;

    # set user permissions
    $res = $self->_set_user_permissions( $dbh, $user->{data}->{id}, $permissions );

    return $on_finish->( $dbh, $res ) if !$res;

    return $on_finish->( $dbh, $user );
}

sub get_users ( $self ) {
    return $self->_db_get_users( $self->{dbh} );
}

sub get_user ( $self, $user_id ) {
    return $self->_db_get_user( $self->{dbh}, $user_id );
}

sub set_user_permissions ( $self, $user_id, $permissions ) {

    # resolve user
    my $user = $self->_db_get_user( $self->{dbh}, $user_id );

    # user wasn't found
    return $user if !$user;

    # begin transaction
    my ( $dbh, $res ) = $self->{dbh}->begin_work;

    # error, strating transaction
    return $res if !$res;

    $res = $self->_set_user_permissions( $dbh, $user->{data}->{id}, $permissions );

    # sql error
    if ( !$res ) {
        my $res1 = $dbh->rollback;

        return $res;
    }
    else {
        my $res1 = $dbh->commit;

        # commit error
        return $res1 if !$res1;

        # fire event if user permissions was changed
        P->fire_event('APP.API.AUTH') if $res == 200;

        return $res;
    }
}

sub _set_user_permissions ( $self, $dbh, $user_id, $permissions ) {
    return res 204 if !$permissions || !$permissions->@*;    # not modified

    my $roles = $self->_db_get_roles($dbh);

    return $roles if !$roles;

    my $role_name_idx = { map { $_->{name} => $_->{id} } values $roles->{data}->%* };

    my $roles_ids;

    for my $perm ( $permissions->@* ) {

        # resolve role id
        my $perm_role_id = looks_like_uuid $perm ? $roles->{data}->{$perm}->{id} : $role_name_idx->{$perm};

        # permission role wasn't found
        return res [ 400, qq[role "$perm" is invlalid] ] if !$perm_role_id;

        push $roles_ids->@*, $perm_role_id;
    }

    return $self->_db_set_user_permissions( $dbh, $user_id, $roles_ids );
}

sub set_user_password ( $self, $user_id, $password ) {

    # resolve user
    my $user = $self->_db_get_user( $self->{dbh}, $user_id );

    # user wasn't found
    return $user if !$user;

    my $password_hash = $self->_generate_user_password_hash( $user->{data}->{name}, $password );

    # password hash genereation error
    return $password_hash if !$password_hash;

    # password hash generated
    my $res = $self->{dbh}->do( q[UPDATE "api_user" SET "hash" = ? WHERE "id" = ?], [ SQL_BYTEA $password_hash->{data}->{hash}, SQL_UUID $user->{data}->{id} ] );

    return res 500 if !$res->{rows};

    # fire AUTH event if user password was changed
    P->fire_event('APP.API.AUTH');

    return res 200;
}

sub set_user_enabled ( $self, $user_id, $enabled ) {

    # resolve user
    my $user = $self->_db_get_user( $self->{dbh}, $user_id );

    # user wasn't found
    return $user if !$user;

    $enabled = 0+ !!$enabled;

    if ( $enabled ^ $user->{data}->{enabled} ) {
        my $res = $self->{dbh}->do( q[UPDATE "api_user" SET "enabled" = ? WHERE "id" = ?], [ SQL_BOOL $enabled, SQL_UUID $user->{data}->{id} ] );

        return $res if !$res;

        return res 500 if !$res->{rows};

        # fire AUTH event if user was disabled
        P->fire_event('APP.API.AUTH') if !$enabled;

        return res 200, { enabled => $enabled };
    }
    else {

        # not modified
        return res 204, { enabled => $enabled };
    }
}

# USER TOKEN
sub _auth_user_token ( $self, $private_token ) {

    # get user token
    my $user_token = $self->{dbh}->selectrow(
        <<'SQL',
            SELECT
                "api_user"."id" AS "user_id",
                "api_user"."name" AS "user_name",
                "api_user"."enabled" AS "user_enabled",
                "api_user_token"."hash" AS "user_token_hash"
            FROM
                "api_user",
                "api_user_token"
            WHERE
                "api_user"."id" = "api_user_token"."user_id"
                AND "api_user_token"."id" = ?
SQL
        [ SQL_UUID $private_token->[1] ]
    );

    # user is disabled
    return res 404 if !$user_token->{data}->{user_enabled};

    # verify token
    my $status = $self->_verify_token_hash( $private_token->[2], $user_token->{data}->{user_token_hash} );

    # token is not valid
    return $status if !$status;

    # token is valid
    return $self->_return_auth( $private_token, $user_token->{data}->{user_id}, $user_token->{data}->{user_name} );
}

sub create_user_token ( $self, $user_id, $desc, $permissions ) {
    my $type = $TOKEN_TYPE_USER_TOKEN;

    # resolve user
    my $user = $self->_db_get_user( $self->{dbh}, $user_id );

    # user wasn't found
    return $user if !$user;

    # generate user token
    my $token = $self->_generate_token($type);

    # token generation error
    return $token if !$token;

    # get user permissions
    my $user_permissions = $self->_db_get_user_permissions( $self->{dbh}, $user->{data}->{id} );

    # error
    return $user_permissions if !$user_permissions;

    # find user permissions id's
    if ( defined $permissions ) {

        # create index by role name
        my $idx = { map { $_ => 1 } $permissions->@* };

        $user_permissions = [ grep { exists $idx->{ $_->{role_name} } } $user_permissions->{data}->@* ];

        # some permissions are invalid or not allowed
        return res 500 if $permissions->@* != $user_permissions->{data}->@*;
    }

    # begin transaction
    my ( $dbh, $res ) = $self->{dbh}->begin_work;

    # error
    return $res if !$res;

    my $on_finish = sub ($res) {
        if ( !$res ) {
            my $res1 = $dbh->rollback;

            return res 500;
        }
        else {
            my $res1 = $dbh->commit;

            # commit error
            return $res1 if !$res1;

            return res 200,
              { id    => $token->{data}->{id},
                type  => $type,
                token => $token->{data}->{token},
              };
        }
    };

    # insert token
    $res = $dbh->do( 'INSERT INTO "api_user_token" ("id", "type", "user_id", "hash", "desc" ) VALUES (?, ?, ?, ?, ?)', [ SQL_UUID $token->{data}->{id}, $type, SQL_UUID $user->{data}->{id}, SQL_BYTEA $token->{data}->{hash}, $desc ] );

    return $on_finish->($res) if !$res;

    # no permissions to insert, eg: root user
    return $on_finish->($res) if !$user_permissions->@*;

    # insert user token permissions
    $res = $dbh->do( [ q[INSERT INTO "api_user_token_permission"], VALUES [ map { { user_token_id => SQL_UUID $token->{data}->{id}, user_permission_id => SQL_UUID $_->{id} } } $user_permissions->{data}->@* ] ] );

    return $on_finish->($res);
}

sub remove_user_token ( $self, $user_token_id ) {
    my $res = $self->{dbh}->do( 'DELETE FROM "api_user_token" WHERE "id" = ? AND "type" = ?', [ SQL_UUID $user_token_id, $TOKEN_TYPE_USER_TOKEN ] );

    return $res if !$res;

    # not found
    return res 204 if !$res->{rows};

    P->fire_event('APP.API.AUTH');

    return res 200;
}

# USER SESSION
sub create_user_session ( $self, $user_id ) {
    my $type = $TOKEN_TYPE_USER_SESSION;

    # resolve user
    my $user = $self->_db_get_user( $self->{dbh}, $user_id );

    # user wasn't found
    return $user if !$user;

    # generate session token
    my $token = $self->_generate_token($type);

    # token generation error
    return $token if !$token;

    # token geneerated
    my $res = $self->{dbh}->do( 'INSERT INTO "api_user_token" ("id", "type", "user_id", "hash") VALUES (?, ?, ?, ?)', [ SQL_UUID $token->{data}->{id}, $type, SQL_UUID $user->{data}->{id}, SQL_BYTEA $token->{data}->{hash} ] );

    return res 500 if !$res->{rows};

    return res 200,
      { id    => $token->{data}->{id},
        type  => $type,
        token => $token->{data}->{token},
      };
}

sub remove_user_session ( $self, $user_sid ) {
    my $res = $self->{dbh}->do( 'DELETE FROM "api_user_token" WHERE "id" = ? AND "type" = ?', [ SQL_UUID $user_sid, $TOKEN_TYPE_USER_SESSION ] );

    return $res if !$res;

    # not found
    return res 204 if !$res->{rows};

    P->fire_event('APP.API.AUTH');

    return res 200;
}

# DB METHODS
sub _db_get_users ( $self, $dbh ) {
    return $dbh->selectall(q[SELECT "id", "name", "enabled", "created" FROM "api_user"]);
}

sub _db_get_user ( $self, $dbh, $user_id ) {
    my $is_uuid = looks_like_uuid $user_id;

    my $user = $dbh->selectrow( qq[SELECT "id", "name", "enabled", "created" FROM "api_user" WHERE "@{[$is_uuid ? 'id' : 'name']}" = ?], $is_uuid ? [ SQL_UUID $user_id ] : [$user_id] );

    # query error
    return $user if !$user;

    # user not found
    return res [ 404, 'User not found' ] if !$user->{data};

    return $user;
}

sub _db_get_roles ( $self, $dbh ) {
    return $dbh->selectall( q[SELECT * FROM "api_role"], key_field => 'id' );
}

sub _db_get_user_permissions ( $self, $dbh, $user_id ) {
    return $dbh->selectall(
        <<'SQL',
            SELECT
                "api_user_permission"."id" AS "id",
                "api_role"."id" AS "role_id",
                "api_role"."name" AS "role_name"
            FROM
                "api_user_permission",
                "api_role"
            WHERE
                "api_user_permission"."role_id" = "api_role"."id"
                AND "api_user_permission"."user_id" = ?
SQL
        [ SQL_UUID $user_id ]
    );
}

sub _db_get_user_token_permissions ( $self, $dbh, $user_token_id ) {
    return $dbh->selectall(
        <<'SQL',
            SELECT
                "api_user_token_permission"."id" AS "id",
                "api_role"."id" AS "role_id",
                "api_role"."name" AS "role_name"
            FROM
                "api_user_token_permission",
                "api_user_permission",
                "api_role"
            WHERE
                "api_user_token_permission"."user_permission_id" = "api_user_permission"."id"
                AND "api_user_permission"."role_id" = "api_role"."id"
                AND "api_user_token_permission"."user_token_id" = ?
SQL
        [ SQL_UUID $user_token_id ]
    );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 103, 131, 187        | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Local

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
