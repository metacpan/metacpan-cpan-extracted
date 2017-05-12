package Mojolicious::Plugin::Vparam::ISIN;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common qw(char_shift);

sub check_isin($) {
    return 'Value not defined'      unless defined $_[0];
    return 'Value not set'          unless length  $_[0];
    return 'Wrong format'           unless $_[0] =~ m{^[A-Z0-9]+$};

    my $str = $_[0];
    my $ch  = char_shift();
    s{([A-Z])}{(ord($1)-$ch)}eg for $str;
    my $crc = 0;
    my @str = reverse split '', $str;
    for my $i ( 0 .. $#str  ) {
        my $digit = $str[$i];
        $digit *= 2 if $i % 2;
        $digit -= 9 if $digit > 9;
        $crc += $digit;
    }
    return 'Checksum error'         if $crc % 10;

    return 0;
}

sub check_maestro {
    return 'Value not defined'      unless defined $_[0];
    return 'Value not set'          unless length  $_[0];
    return 'Wrong format'           unless $_[0] =~ m{^\d+$};

    return 0;
}

sub check_creditcard {
    return 'Value not defined'      unless defined $_[0];
    return 'Value not set'          unless length  $_[0];
    return 'Wrong format'           unless $_[0] =~ m{^\d+$};

    return 0;
}

sub parse_isin($) {
    my ($str) = @_;
    return undef unless defined $str;
    s{[^a-zA-Z0-9]}{}g for $str;
    return uc $str;
}

sub parse_maestro($) {
    my ($str) = @_;
    return undef unless defined $str;
    s{\D+}{}g for $str;
    return $str;
}

sub parse_creditcard($) {
    return parse_isin $_[0];
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        isin        =>
            pre     => sub { parse_isin         $_[1] },
            valid   => sub { check_isin         $_[1] },
    );

    $app->vtype(
        maestro     =>
            pre     => sub { parse_maestro      $_[1] },
            valid   => sub { check_maestro      $_[1] },
    );

    $app->vtype(
        creditcard  =>
            pre     => sub { parse_creditcard   $_[1] },
            valid   => sub { check_creditcard   $_[1] },
    );

    return;
}

1;
