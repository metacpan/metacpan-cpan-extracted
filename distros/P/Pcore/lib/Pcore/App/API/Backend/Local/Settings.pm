package Pcore::App::API::Backend::Local::Settings;

use Pcore -role, -res, -sql;

sub settings_load ( $self ) {
    state $q1 = $self->{dbh}->prepare(q[SELECT * FROM "settings" WHERE "id" = 1]);

    my $settings = $self->{dbh}->selectrow($q1);

    if ($settings) {
        delete $settings->{data}->{id};

        P->fire_event( 'app.api.settings.updated', $settings->{data} );
    }

    return $settings;
}

# TODO check, if settings was updated
sub settings_update ( $self, $settings ) {
    $settings->{smtp_tls}                = SQL_BOOL $settings->{smtp_tls}                if exists $settings->{smtp_tls};
    $settings->{telegram_bot_enabled}    = SQL_BOOL $settings->{telegram_bot_enabled}    if exists $settings->{telegram_bot_enabled};
    $settings->{telegram_signin_enabled} = SQL_BOOL $settings->{telegram_signin_enabled} if exists $settings->{telegram_signin_enabled};

    my $res = $self->{dbh}->do( [ q[UPDATE "settings"], SET [$settings], 'WHERE "id" = 1' ] );

    $self->settings_load if $res;

    return $res;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::Settings

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
