package Mojolicious::Plugin::Vparam::RU;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

sub check_inn($) {
    return 'Value not defined'      unless defined $_[0];
    return 'Value not set'          unless length  $_[0];
    return 'Wrong format'           unless $_[0] =~ m{^(?:\d{10}|\d{12})$};

    my @str = split '', $_[0];
    if( @str == 10 ) {
        return 'Checksum error'
            unless $str[9] eq
                (((
                    2 * $str[0] + 4 * $str[1] + 10 * $str[2] + 3 * $str[3] +
                    5 * $str[4] + 9 * $str[5] + 4  * $str[6] + 6 * $str[7] +
                    8 * $str[8]
                ) % 11 ) % 10);
        return 0;
    } elsif( @str == 12 ) {
        return 'Checksum error'
            unless $str[10] eq
                (((
                    7 * $str[0] + 2 * $str[1] + 4 * $str[2] + 10 * $str[3] +
                    3 * $str[4] + 5 * $str[5] + 9 * $str[6] + 4  * $str[7] +
                    6 * $str[8] + 8 * $str[9]
                ) % 11 ) % 10)
                && $str[11] eq
                (((
                    3  * $str[0] + 7 * $str[1] + 2 * $str[2] + 4 * $str[3] +
                    10 * $str[4] + 3 * $str[5] + 5 * $str[6] + 9 * $str[7] +
                    4  * $str[8] + 6 * $str[9] + 8 * $str[10]
                ) % 11 ) % 10);
        return 0;
    }
    return 'Must be 10 or 12 digits';
}

sub check_kpp($) {
    return 'Value not defined'      unless defined $_[0];
    return 'Value not set'          unless length  $_[0];
    return 'Wrong format'           unless $_[0] =~ m{^\d{9}$};
    return 0;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        inn         =>
            pre     => sub { trim       $_[1] },
            valid   => sub { check_inn  $_[1] },
    );

    $app->vtype(
        kpp         =>
            pre     => sub { trim       $_[1] },
            valid   => sub { check_kpp  $_[1] },
    );

    return;
}

1;
