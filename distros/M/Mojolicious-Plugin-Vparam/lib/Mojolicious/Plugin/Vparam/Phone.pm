package Mojolicious::Plugin::Vparam::Phone;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

sub check_phone($) {
    return 'Value not defined'          unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 'The number should be in the format +...'
        unless $_[0] =~ m{^\+\d};
    return 'The number must be a minimum of 11 digits'
        unless $_[0] =~ m{^\+\d{11}};
    return 'The number should be no more than 16 digits'
        unless $_[0] =~ m{^\+\d{11,16}(?:\D|$)};
    return 'Wrong format'
        unless $_[0] =~ m{^\+\d{11,16}(?:[pw]\d+)?$};
    return 0;
}

sub fix_phone($$$) {
    my ($sign, $phone, $code) = @_;

    if( $code eq 'ru' ) {
        unless( $sign ) {
            s{^8}{7} for $phone;
        }
    }

    return $phone;
}

sub parse_phone($$$$) {
    my ($str, $country, $region, $fix_code) = @_;
    return undef unless $str;

    # Clear
    s{[.,]}{w}g, s{[^0-9pw+]}{}ig, s{w{2,}}{w}ig, s{p{2,}}{p}ig for $str;

    # Split
    my ($sign, $phone, $pause, $add) = $str =~ m{^(\+)?(\d+)([wp])?(\d+)?$}i;
    return undef unless $phone;

    # Add country and region codes if defined
    $phone = $region  . $phone  if $region  and 11 > length $phone;
    $phone = $country . $phone  if $country and 11 > length $phone;
    return undef unless 10 <= length $phone;

    # Some country deprication fix
    $phone = fix_phone $sign, $phone, $fix_code;

    $str = '+' . $phone;
    $str = $str . lc $pause     if defined $pause;
    $str = $str . $add          if defined $add;

    return $str;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        phone       =>
            pre     => sub { parse_phone
                                trim( $_[1] ),
                                $conf->{phone_country},
                                $conf->{phone_region},
                                $conf->{phone_fix}
                           },
            valid   => sub { check_phone        $_[1] },
    );

    return;
}

1;
