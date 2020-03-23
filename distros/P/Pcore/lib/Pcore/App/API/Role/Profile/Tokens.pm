package Pcore::App::API::Role::Profile::Tokens;

use Pcore -role, -sql, -res;

with qw[Pcore::App::API::Role::Read];

has read_max_limit        => undef;
has read_default_order_by => sub { [ [ 'created', 'DESC' ] ] };

sub API_read ( $self, $auth, $args ) {
    my $where = WHERE [ '"user_id" =', \$auth->{user_id} ];

    # get by id
    if ( exists $args->{id} ) {
        $where &= WHERE [ '"id" = ', SQL_UUID $args->{id} ];
    }

    my $total_query = [ 'SELECT COUNT(*) AS "total" FROM "user_token"', $where ];

    my $main_query = [ 'SELECT * FROM "user_token"', $where ];

    return $self->_read( $total_query, $main_query, $args );
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
    my $token_id = $args->{where}->{token_id}->[1];

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
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Role::Profile::Tokens

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
