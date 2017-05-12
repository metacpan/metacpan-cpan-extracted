package Mojolicious::Plugin::Vparam::Numbers;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

sub check_int($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 0;
}

sub check_numeric($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 0;
}

sub check_money($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];

    my $numeric = check_numeric $_[0];
    return $numeric if $numeric;

    return 'Invalid fractional part'
        if $_[0] =~ m{\.} && $_[0] !~ m{\.\d{0,2}$};
    return 0;
}

sub check_percent($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];

    my $numeric = check_numeric $_[0];
    return $numeric if $numeric;

    return 'Value must be greater than 0'   unless $_[0] >= 0;
    return 'Value must be less than 100'    unless $_[0] <= 100;
    return 0;
}

sub check_lon($) {
    return 'Value not defined'     unless defined $_[0];

    my $numeric = check_numeric $_[0];
    return $numeric if $numeric;

    return 'Value should not be less than -180°'    unless $_[0] >= -180;
    return 'Value should not be greater than 180°'  unless $_[0] <= 180;
    return 0;
}

sub check_lat($) {
    return 'Value not defined'      unless defined $_[0];

    my $numeric = check_numeric $_[0];
    return $numeric if $numeric;

    return 'Value should not be less than -90°'     unless $_[0] >= -90;
    return 'Value should not be greater than 90°'   unless $_[0] <= 90;
    return 0;
}

sub parse_int($) {
    my ($str) = @_;
    return undef unless defined $str;
    my ($int) = $str =~ m{([-+]?\d+)};
    return $int;
}

sub parse_number($) {
    my ($str) = @_;
    return undef unless defined $str;
    my ($number) = $str =~ m{
        (
            [-+]?
            (?:
                \d+(?:[\.,]\d*)?
                |
                [\.,]\d+
            )
        )
    }x;
    return undef unless defined $number;
    tr{,}{.} for $number;
    return $number;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        int         =>
            pre     => sub{ parse_int       $_[1] },
            valid   => sub{ check_int       $_[1] },
            post    => sub{ defined         $_[1]   ? 0 + $_[1] : undef },
    );

    my %numeric = (
        pre     => sub{ parse_number    $_[1] },
        valid   => sub{ check_numeric   $_[1] },
        post    => sub{ defined         $_[1] ? 0.0 + $_[1] : undef },
    );
    $app->vtype(numeric => %numeric);
    $app->vtype(number  => %numeric);

    $app->vtype(
        money       =>
            pre     => sub{ parse_number    $_[1] },
            valid   => sub{ check_money     $_[1] },
            post    => sub{ defined         $_[1] ? 0.0 + $_[1] : undef },
    );

    $app->vtype(
        percent     =>
            pre     => sub{ parse_number    $_[1] },
            valid   => sub{ check_percent   $_[1] },
            post    => sub{ defined         $_[1] ? 0.0 + $_[1] : undef },
    );

    $app->vtype(
        lon         =>
            pre     => sub{ parse_number    $_[1] },
            valid   => sub{ check_lon       $_[1] },
            post    => sub{ defined         $_[1] ? 0.0 + $_[1] : undef },
    );

    $app->vtype(
        lat         =>
            pre     => sub{ parse_number    $_[1] },
            valid   => sub{ check_lat       $_[1] },
            post    => sub{ defined         $_[1] ? 0.0 + $_[1] : undef },
    );


    return;
}

1;
