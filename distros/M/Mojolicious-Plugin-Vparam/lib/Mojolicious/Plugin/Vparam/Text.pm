package Mojolicious::Plugin::Vparam::Text;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

sub check_str($) {
    return 'Value is not defined'       unless defined $_[0];
    return 0;
}

sub check_text($) {
    return check_str $_[0];
}

sub check_password($$) {
    return 'Value is not defined'       unless defined $_[0];
    return sprintf 'The length should be greater than %s', $_[1]
        unless length( $_[0] ) >= $_[1];

    return 'Value must contain characters and digits'
        unless $_[0] =~ m{\d} and $_[0] =~ m{\D};

    return 0;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        str         =>
            pre     => sub{ trim            $_[1] },
            valid   => sub{ check_str       $_[1] },
    );

    $app->vtype(
        text        =>
            valid   => sub{ check_str       $_[1] },
    );

    $app->vtype(
        password    =>
            valid   => sub{ check_password $_[1], $conf->{password_min} },
    );

    return;
}

1;
