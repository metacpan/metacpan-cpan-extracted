package Mojolicious::Plugin::Vparam::UUID;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

sub check_uuid($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 'Wrong format'
        unless $_[0] =~ m{^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$}i;
    return 0;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        uuid        =>
            pre     => sub{ trim            $_[1] },
            valid   => sub{ check_uuid      $_[1] },
            post    => sub{ defined         $_[1] ? lc $_[1] : undef },
    );

    return;
}

1;
