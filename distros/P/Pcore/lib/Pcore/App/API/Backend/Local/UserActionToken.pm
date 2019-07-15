package Pcore::App::API::Backend::Local::UserActionToken;

use Pcore -role, -sql, -res;
use Pcore::App::API qw[:PRIVATE_TOKEN];

sub user_action_token_create ( $self, $user_id, $token_type ) {
    my ( $res, $dbh ) = $self->{dbh}->get_dbh;

    # unable to get dbh
    return $res if !$res;

    # lowecase user id
    $user_id = lc $user_id;

    state $q1 = $dbh->prepare('SELECT "id", "email" FROM "user" WHERE "enabled" = TRUE AND ("name" = ? OR "email" = ?)');

    my $user = $dbh->selectrow( $q1, [ $user_id, $user_id ] );

    # dbh error
    return $user if !$user;

    # user was not found or email is not set
    return res 404 if !$user->{data} || !$user->{data}->{email};

    # generate token
    my $token = $self->_generate_token($token_type);

    # start transaction
    $res = $dbh->begin_work;

    # unable to start transaction
    return $res if !$res;

    state $on_finish = sub ( $dbh, $res ) {
        if ( !$res ) {
            my $res1 = $dbh->rollback;
        }
        else {
            my $res1 = $dbh->commit;

            # commit error
            return $res1 if !$res1;
        }

        return $res;
    };

    # insert hash
    state $q2 = $dbh->prepare('INSERT INTO "auth_hash" ("id", "hash") VALUES (?, ?)');

    $res = $dbh->do( $q2, [ SQL_UUID $token->{data}->{id}, SQL_BYTEA $token->{data}->{hash} ] );

    # dbh error
    return $on_finish->( $dbh, $res ) if !$res;

    # insert action token
    state $q3 = $dbh->prepare('INSERT INTO "user_action_token" ("id", "user_id", "type", "email") VALUES (?, ?, ?, ?)');

    $res = $dbh->do( $q3, [ SQL_UUID $token->{data}->{id}, $user->{data}->{id}, $token_type, $user->{data}->{email} ] );

    # dbh error
    return $on_finish->( $dbh, $res ) if !$res;

    return $on_finish->(
        $dbh,
        res 200,
        {   email => $user->{data}->{email},
            token => $token->{data}->{token},
            type  => $token_type,
        }
    );
}

sub user_action_token_verify ( $self, $token, $token_type ) {
    my $private_token = $self->_unpack_token($token);

    return res 400 if !$private_token;

    state $q1 = $self->{dbh}->prepare('SELECT "user_action_token".*, "auth_hash"."hash" FROM "user_action_token", "auth_hash" WHERE "user_action_token"."id" = "auth_hash"."id" AND "user_action_token"."id" = ? AND "user_action_token"."type" = ?');

    my $res = $self->{dbh}->selectrow( $q1, [ $private_token->[$PRIVATE_TOKEN_ID], $token_type ] );

    return $res if !$res;

    return res 404 if !$res->{data};

    # verify token, token is not valid
    return res [ 400, 'Invalid token' ] if !$self->_verify_private_token( $private_token, $res->{data}->{hash} );

    return res 200,
      { user_id => $res->{data}->{user_id},
        email   => $res->{data}->{email},
      };
}

sub user_action_token_remove ( $self, $token_type, $email ) {
    state $q1 = $self->{dbh}->prepare('DELETE FROM "user_action_token" WHERE "type" = ? AND "email" = ?');

    return $self->{dbh}->do( $q1, [ $token_type, $email ] );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::UserActionToken

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
