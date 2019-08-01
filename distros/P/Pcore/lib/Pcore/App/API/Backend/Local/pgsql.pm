package Pcore::App::API::Backend::Local::pgsql;

use Pcore -class, -sql, -res;
use Pcore::App::API qw[:ROOT_USER];

with qw[Pcore::App::API::Backend::Local];

sub _db_add_schema_patch ( $self, $dbh ) {
    $dbh->load_schema( $ENV->{share}->get_location('/Pcore/dbh/api/pgsql'), 'api' );

    return;
}

sub _db_insert_user ( $self, $dbh, $user_name ) {
    my $res;

    if ( $self->user_is_root($user_name) ) {
        state $q1 = $dbh->prepare(q[INSERT INTO "user" ("id", "name", "enabled") VALUES (?, ?, FALSE) ON CONFLICT DO NOTHING RETURNING "id", "guid"]);

        # insert user
        $res = $dbh->selectrow( $q1, [ $ROOT_USER_ID, $user_name ] );
    }
    else {
        state $q1 = $dbh->prepare(q[INSERT INTO "user" ("name", "enabled") VALUES (?, FALSE) ON CONFLICT DO NOTHING RETURNING "id", "guid"]);

        # insert user
        $res = $dbh->selectrow( $q1, [$user_name] );
    }

    # dbh error
    return $res if !$res;

    # username already exists
    return res [ 400, 'Username is already exists' ] if !$res->{data};

    return $res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 8                    | * Private subroutine/method '_db_add_schema_patch' declared but not used                                       |
## |      | 14                   | * Private subroutine/method '_db_insert_user' declared but not used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::pgsql

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
