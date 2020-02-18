package Pcore::App::API::Role::Admin::Users;

use Pcore -role, -sql;
use Pcore::Util::Scalar qw[is_plain_hashref];

with qw[Pcore::App::API::Role::Read];

has default_gravatar       => ();
has default_gravatar_image => ();
has read_root              => undef;

has max_limit        => 100;
has default_order_by => sub { [ [ 'name', 'DESC' ] ] };

sub API_read ( $self, $auth, $args ) {
    my $where = WHERE;

    # get by id
    if ( exists $args->{id} ) {
        $where &= WHERE [ '"user"."id" = ', \$args->{id} ];
    }

    # get all matched rows
    else {

        # filter root
        if ( !$self->{read_root} ) {
            $where &= WHERE ['"user"."id" != 1'];
        }

        # filter search
        if ( my $search = delete $args->{where}->{search} ) {
            $where &= WHERE [ { 'user.name' => $search }, 'OR', { 'user.email' => $search }, 'OR', { 'user.telegram_name' => $search } ];
        }

        # filter status
        if ( exists $args->{where}->{enabled} ) {
            $where &= [ '"user"."enabled"', IN [ map { SQL_BOOL $_} $args->{where}->{enabled}->[1]->@* ] ];
        }
    }

    my $total_query = [ 'SELECT COUNT(*) AS "total" FROM "user"', $where ];

    my $main_query = [
        <<"SQL",
        SELECT
            *,
            CASE
                WHEN "user"."gravatar" IS NOT NULL THEN 'https://s.gravatar.com/avatar/' || "user"."gravatar" || '?d=@{[ $self->{default_gravatar_image} ]}'
                ELSE '@{[ $self->{default_gravatar} ]}'
            END "avatar"
        FROM
            "user"
SQL
        $where
    ];

    my $res = $self->_read( $total_query, $main_query, $args );

    return $res;
}

sub API_create ( $self, $auth, $args ) {

    # lowecase user name
    $args->{username} = lc $args->{username};

    # validate email
    if ( $args->{email} ) {

        # lowercase email address
        $args->{email} = lc $args->{email};

        return [ 400, 'Email address is not valid' ] if !$self->{api}->validate_email( $args->{email} );
    }
    else {
        undef $args->{email};
    }

    my $permissions = $args->{permissions};

    # check permissions
    my $error;
    my $auth_permissions = $auth->{permissions};

    for my $name ( keys $permissions->%* ) {
        if ( !$auth_permissions->{$name} ) {
            $error = 1;

            last;
        }
    }

    return [ 400, q[You can't set some user permissions] ] if $error;

    my $dbh = $self->{dbh};

    # check, that email is unique
    if ( $args->{email} ) {
        my $res = $dbh->selectrow( 'SELECT "id" FROM "user" WHERE "email" = ?', [ $args->{email} ] );

        return $res if !$res;

        return [ 400, q[Email address is already taken by the other user] ] if $res->{data};
    }

    # create user
    my $res = $self->{api}->user_create( $args->{username}, $args->{password}, $args->{enabled}, $permissions );

    # error creating user
    return $res if !$res;

    # update user email
    if ( $args->{email} ) {
        $res = $dbh->do(
            'UPDATE "user" SET "email" = ? WHERE "id" = ?',
            [   $args->{email},    #
                $res->{data}->{id},
            ]
        );
    }

    return $res;
}

sub API_delete ( $self, $auth, $user_id ) {
    my $res = $self->{api}->user_delete($user_id);

    return $res;
}

sub API_set_enabled ( $self, $auth, $user_id, $enabled ) {

    # user can't disable itselt
    return [ 400, q[You can't disable yourself] ] if $auth->{user_id} eq $user_id;

    my $res = $self->{api}->user_set_enabled( $user_id, $enabled );

    return $res;
}

sub API_read_permissions ( $self, $auth, $args ) {
    my $user_id = $args->{where}->{user_id}->[1];

    my $permissions;
    my $auth_permissions = $auth->{permissions};

    if ( $self->{api}->user_is_root($user_id) ) {
        for my $name ( sort keys $auth_permissions->%* ) {
            push $permissions->@*,
              { name     => $name,
                enabled  => 1,
                can_edit => 0,
              };
        }
    }
    else {
        my $is_me = $user_id eq $auth->{user_id};

        my $user_permissions = $self->{api}->user_get_permissions($user_id);

        # request error
        return $user_permissions if !$user_permissions;

        $user_permissions = $user_permissions->{data};

        for my $name ( sort keys $user_permissions->%* ) {
            push $permissions->@*,
              { name     => $name,
                enabled  => $user_permissions->{$name},
                can_edit => $is_me ? 0 : $auth_permissions->{$name},
              };
        }
    }

    return 200, $permissions;
}

sub API_write_permissions ( $self, $auth, $user_id, $permissions ) {
    my $is_me = $user_id eq $auth->{user_id};

    # user can't edit own permissions
    return [ 400, q[You can't modify own permissions] ] if $is_me;

    # user can't edit root permissions
    return [ 400, q[Can't modify "root" user permissions] ] if $self->{api}->user_is_root($user_id);

    # check permissions
    my $error;
    my $auth_permissions = $auth->{permissions};

    for my $name ( keys $permissions->%* ) {
        if ( !$auth_permissions->{$name} ) {
            $error = 1;

            last;
        }
    }

    if ($error) {
        return [ 400, q[You can't modify some permissions] ];
    }
    else {
        my $res = $self->{api}->user_set_permissions( $user_id, $permissions );

        return $res;
    }
}

sub API_suggest ( $self, $auth, $args ) {
    my $where = WHERE do {
        if ( defined $args->{where}->{name}->[1] ) {
            my $val = lc "%$args->{where}->{name}->[1]%";

            [ '"name" LIKE', \$val, 'OR "email" LIKE', \$val, 'OR "telegram_name" LIKE', \$val ];
        }
        else {
            undef;
        }
    };

    my $res = $self->{dbh}->selectall( [ 'SELECT "id", "name" FROM "user"', WHERE $where, ORDER_BY ['name'], 'LIMIT 100' ] );

    return 200, $res->{data};
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Role::Admin::Users

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
