package Mojolicious::Plugin::Vparam::JSON;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common qw(decode_json);

use Mojo::JSON;

sub parse_json($) {
    my $str = shift;
    return undef unless defined $str;
    return undef unless length  $str;
    return decode_json $str;
}

sub check_json($) {
    return 'Wrong format'           unless defined $_[0];
    return 0;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        json        =>
            pre     => sub { parse_json         $_[1] },
            valid   => sub { check_json         $_[1] },
    );

    return;
}

1;
