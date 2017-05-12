package Mojolicious::Plugin::Vparam::Bool;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

sub check_bool($) {
    return 'Wrong format'               unless defined $_[0];
    return 0;
}

sub parse_bool($) {
    my ($str) = @_;
    # HTML forms do not transmit if checkbox off
    return 0 unless defined $str;
    return 0 unless length  $str;
    return 0 if $str =~ m{^(?:0|no|false|fail)$}i;
    return 1 if $str =~ m{^(?:1|yes|true|ok)$}i;
    return undef;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        bool        =>
            pre     => sub { parse_bool trim    $_[1] },
            valid   => sub { check_bool         $_[1] },
    );

    return;
}

1;
