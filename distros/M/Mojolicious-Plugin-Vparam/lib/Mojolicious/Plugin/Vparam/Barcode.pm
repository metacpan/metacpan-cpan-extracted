package Mojolicious::Plugin::Vparam::Barcode;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

sub check_barcode($) {
    return 'Value not defined'      unless defined $_[0];
    return 'Value not set'          unless length  $_[0];
    return 'Wrong format'           unless $_[0] =~ m{^[0-9]+$};

    my $crc = 0;
    my @str = reverse split '', $_[0];
    for my $i ( 0 .. $#str  ) {
        my $digit = $str[$i];
        $digit *= 3 if $i % 2;
        $crc += $digit;
    }
    return 'Checksum error'         if $crc % 10;

    return 0;
}

sub parse_barcode($) {
    my ($str) = @_;
    return undef unless defined $str;
    s{[^0-9]}{}g for $str;
    return $str;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        barcode     =>
            pre     => sub { parse_barcode      $_[1] },
            valid   => sub { check_barcode      $_[1] },
    );

    return;
}

1;
