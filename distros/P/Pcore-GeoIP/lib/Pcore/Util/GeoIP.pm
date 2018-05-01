package Pcore::Util::GeoIP;

use Pcore -const;

const our $TYPE_COUNTRY    => 1;
const our $TYPE_COUNTRY_V6 => 2;
const our $TYPE_CITY       => 3;
const our $TYPE_CITY_V6    => 4;
const our $TYPE_COUNTRY2   => 5;
const our $TYPE_CITY2      => 6;

const our $RES => {
    $TYPE_COUNTRY    => [ 'data/geoip_country.dat',    'https://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz' ],
    $TYPE_COUNTRY_V6 => [ 'data/geoip_country_v6.dat', 'https://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz' ],
    $TYPE_CITY       => [ 'data/geoip_city.dat',       'https://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz' ],
    $TYPE_CITY_V6    => [ 'data/geoip_city_v6.dat',    'https://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz' ],
    $TYPE_COUNTRY2   => [ 'data/geoip2_country.mmdb',  'https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.mmdb.gz' ],
    $TYPE_CITY2      => [ 'data/geoip2_city.mmdb',     'http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz' ],
};

my $H;

sub clear {
    undef $H;

    return;
}

sub update_all ($cb = undef) {
    my $rouse_cb = defined wantarray ? Coro::rouse_cb : ();

    my $success_all = 1;

    my $cv = AE::cv sub {
        $rouse_cb ? $cb ? $rouse_cb->( $cb->($success_all) ) : $rouse_cb->($success_all) : $cb ? $cb->($success_all) : ();

        return;
    };

    $cv->begin;

    for ( keys $RES->%* ) {
        $cv->begin;

        update(
            $_,
            sub ($success) {
                $success_all = 0 if !$success;

                $cv->end;

                return;
            }
        );
    }

    $cv->end;

    return $rouse_cb ? Coro::rouse_wait $rouse_cb : ();
}

sub update ( $type, $cb = undef ) {
    state $init = !!require IO::Uncompress::Gunzip;

    return P->http->get(
        $RES->{$type}->[1],
        buf_size    => 1,
        on_progress => 1,
        on_finish   => sub ($res) {
            my $success = 0;

            if ( $res->{status} == 200 ) {
                eval {
                    my $temp = P->file->tempfile;

                    IO::Uncompress::Gunzip::gunzip( $res->{body}, $temp->path, BinModeOut => 1 );

                    $ENV->{share}->write( 'Pcore-GeoIP', $RES->{$type}->[0], $temp->path );

                    delete $H->{$type};

                    $success = 1;
                };
            }

            return $cb ? $cb->($success) : $success;
        }
    );
}

sub country {
    _get_h($TYPE_COUNTRY) if !exists $H->{$TYPE_COUNTRY};

    return $H->{$TYPE_COUNTRY};
}

sub country_v6 {
    _get_h($TYPE_COUNTRY_V6) if !exists $H->{$TYPE_COUNTRY_V6};

    return $H->{$TYPE_COUNTRY_V6};
}

sub country2 {
    _get_h($TYPE_COUNTRY2) if !exists $H->{$TYPE_COUNTRY2};

    return $H->{$TYPE_COUNTRY2};
}

sub city {
    _get_h($TYPE_CITY) if !exists $H->{$TYPE_CITY};

    return $H->{$TYPE_CITY};
}

sub city_v6 {
    _get_h($TYPE_CITY_V6) if !exists $H->{$TYPE_CITY_V6};

    return $H->{$TYPE_CITY_V6};
}

sub city2 {
    _get_h($TYPE_CITY2) if !exists $H->{$TYPE_CITY2};

    return $H->{$TYPE_CITY2};
}

sub _get_h ($type) {
    my $path = $ENV->{share}->get( $RES->{$type}->[0] );

    return if !$path;

    if ( $type == $TYPE_COUNTRY2 || $type == $TYPE_CITY2 ) {
        state $init = !!require MaxMind::DB::Reader;

        $H->{$type} = MaxMind::DB::Reader->new( file => $path );
    }
    else {
        state $init = !!require Geo::IP;

        $H->{$type} = Geo::IP->open( $path, Geo::IP::GEOIP_MEMORY_CACHE() | Geo::IP::GEOIP_CHECK_CACHE() );
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 73                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::GeoIP - Maxmind GeoIP wrapper

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
