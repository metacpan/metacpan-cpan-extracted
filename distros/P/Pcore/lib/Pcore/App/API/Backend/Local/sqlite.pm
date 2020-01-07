package Pcore::App::API::Backend::Local::sqlite;

use Pcore -class, -sql, -res;
use Pcore::App::API qw[:ROOT_USER];
use Pcore::Util::UUID qw[uuid_v4_str];

with qw[Pcore::App::API::Backend::Local];

sub _db_add_schema_patch ( $self, $dbh ) {
    $dbh->load_schema( $ENV->{share}->get_location('/Pcore/db/api/sqlite'), 'api' );

    return;
}

sub _db_insert_user ( $self, $dbh, $user_name ) {
    my $res;

    my $guid = uuid_v4_str;

    if ( $self->user_is_root($user_name) ) {
        state $q1 = $dbh->prepare(q[INSERT INTO "user" ("id", "guid", "name", "enabled") VALUES (?, ?, ?, FALSE) ON CONFLICT DO NOTHING]);

        # insert user
        $res = $dbh->do( $q1, [ $ROOT_USER_ID, $guid, $user_name ] );
    }
    else {
        state $q1 = $dbh->prepare(q[INSERT INTO "user" ("guid", "name", "enabled") VALUES (?, ?, FALSE) ON CONFLICT DO NOTHING]);

        # insert user
        $res = $dbh->do( $q1, [ $guid, $user_name ] );
    }

    # dbh error
    return $res if !$res;

    # username already exists
    return res [ 400, 'Username is already exists' ] if !$res->{rows};

    return res 200, { id => $dbh->last_insert_id, guid => $guid };
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 9                    | * Private subroutine/method '_db_add_schema_patch' declared but not used                                       |
## |      | 15                   | * Private subroutine/method '_db_insert_user' declared but not used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::sqlite

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
