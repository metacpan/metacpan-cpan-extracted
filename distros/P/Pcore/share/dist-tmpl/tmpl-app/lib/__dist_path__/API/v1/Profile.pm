package <: $module_name ~ "::API::v1::Profile" :>;

use Pcore -const, -class, -sql, -res;
use Pcore::App::API qw[:PRIVATE_TOKEN :TOKEN_TYPE];
use <: $module_name ~ "::Const qw[:PERMS]" :>;

extends qw[Pcore::App::API::Base];

const our $API_NAMESPACE_PERMS => [$PERMS_ANY_AUTHENTICATED_USER];

sub API_read ( $self, $auth, @ ) {
    state $q1 = $self->{dbh}->prepare('SELECT "name", "email", "email_confirmed", "telegram_name" FROM "user" WHERE "id" = ?');

    my $res = $self->{dbh}->selectrow( $q1, [ $auth->{user_id} ] );

    return $res;
}

sub API_change_password ( $self, $auth, $password ) {
    my $res = $self->{api}->user_set_password( $auth->{user_id}, $password );

    return $res;
}

sub API_set_email ( $self, $auth, $email ) {
    if ($email) {

        # lowercase email address
        $email = lc $email;

        return [ 400, 'Email address is not valid' ] if !$self->{api}->validate_email($email);
    }
    else {
        undef $email;
    }

    state $q1 = $self->{dbh}->prepare('UPDATE "user" SET "email" = ? WHERE "id" = ?');

    my $res = $self->{dbh}->do( $q1, [ $email, $auth->{user_id} ] );

    return $res;
}

sub API_set_telegram_username ( $self, $auth, $telegram_name ) {
    $telegram_name = lc $telegram_name;

    return [ 400, 'Telegram user name is not valid' ] if !$self->{api}->validate_telegram_user_name($telegram_name);

    state $q1 = $self->{dbh}->prepare('UPDATE "user" SET "telegram_name" = ? WHERE "id" = ?');

    my $res = $self->{dbh}->do( $q1, [ $telegram_name, $auth->{user_id} ] );

    return $res;
}

sub API_set_locale ( $self, $auth, $locale ) {
    state $locales = $self->{app}->get_locales;

    return 400 if !$locales->{$locale};

    my $dbh = $self->{dbh};

    my $res = $dbh->do( q[UPDATE "user" SET "locale" = ? WHERE "id" = ?], [ $locale, $auth->{user_id} ] );

    return $res;
}

sub API_signout ( $self, $auth ) {

    # request is authenticated from the session token
    if ( $auth->{private_token}->[$PRIVATE_TOKEN_TYPE] && $auth->{private_token}->[$PRIVATE_TOKEN_TYPE] == $TOKEN_TYPE_SESSION ) {

        # remove user session
        return $self->{api}->user_session_remove( $auth->{private_token}->[$PRIVATE_TOKEN_ID] );
    }

    # not a session token
    return 400;
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
## |    1 | 83                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 87 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::API::v1::Profile" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
