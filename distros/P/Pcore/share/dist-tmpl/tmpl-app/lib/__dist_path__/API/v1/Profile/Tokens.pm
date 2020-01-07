package <: $module_name ~ "::API::v1::Profile::Tokens" :>;

use Pcore -const, -class, -sql, -res;
use <: $module_name ~ "::Const qw[:PERMS]" :>;

extends qw[Pcore::App::API::Base];

with qw[Pcore::App::API::Role::Read];

const our $API_NAMESPACE_PERMS => [$PERMS_ANY_AUTHENTICATED_USER];

sub API_read ( $self, $auth, $args ) {
    state $total_sql = 'SELECT COUNT(*) AS "total" FROM "user_token"';
    state $main_sql  = 'SELECT * FROM "user_token"';

    my $owner = WHERE [ '"user_id" =', \$auth->{user_id} ];

    my $where;

    # get by id
    if ( exists $args->{id} ) {
        $where = $owner & WHERE [ '"id" = ', SQL_UUID $args->{id} ];
    }

    # get all matched rows
    else {

        # default sort
        $args->{sort} = [ [ 'created', 'DESC' ] ] if !$args->{sort};

        $where = $owner;
    }

    return $self->_read( $args, $total_sql, $main_sql, $where, 100 );
}

sub API_create ( $self, $auth, $args ) {
    my $token = $self->{api}->user_token_create( $auth->{user_id}, $args->{name}, $args->{enabled}, $args->{permissions} );

    return $token;
}

sub API_delete ( $self, $auth, $token_id ) {
    my $res = $self->_check_token_permissions( $auth->{user_id}, $token_id );

    return $res if !$res;

    $res = $self->{api}->user_token_remove($token_id);

    return $res;
}

sub API_set_enabled ( $self, $auth, $token_id, $enabled ) {
    my $res = $self->_check_token_permissions( $auth->{user_id}, $token_id );

    return $res if !$res;

    $res = $self->{api}->user_token_set_enabled( $token_id, $enabled );

    return $res;
}

sub API_read_permissions ( $self, $auth, $args ) {
    my $token_id = $args->{filter}->{token_id}->[1];

    my $res = $self->_check_token_permissions( $auth->{user_id}, $token_id );

    return $res if !$res;

    my $token_permissions = $self->{api}->user_token_get_permissions_for_edit($token_id);

    return $token_permissions;
}

sub API_write_permissions ( $self, $auth, $token_id, $permissions ) {
    my $res = $self->_check_token_permissions( $auth->{user_id}, $token_id );

    return $res if !$res;

    $res = $self->{api}->user_token_set_permissions( $token_id, $permissions );

    return $res;
}

sub _check_token_permissions ( $self, $user_id, $token_id ) {
    my $dbh = $self->{dbh};

    state $q1 = $dbh->prepare('SELECT * FROM "user_token" WHERE "id" = ?');

    my $token = $dbh->selectrow( $q1, [$token_id] );

    # dbh call error
    return $token if !$token;

    return res 404 if !$token->{data};

    # no permissions to modify token
    return res [ 400, q[You don't have permissions to edit this token] ] if $token->{data}->{user_id} ne $user_id;

    return res 200;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1, 4                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 105                  | Documentation::RequirePackageMatchesPodName - Pod NAME on line 109 does not match the package declaration      |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::API::v1::Profile::Tokens" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
