package Pcore::Lib::GeoIP;

use Pcore -const;

const our $TYPE_COUNTRY => 1;
const our $TYPE_CITY    => 2;

const our $RES => {
    $TYPE_COUNTRY => [ 'data/geoip2_country.mmdb', 'https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.mmdb.gz' ],
    $TYPE_CITY    => [ 'data/geoip2_city.mmdb',    'http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz' ],
};

my $H;

sub clear {
    undef $H;

    return;
}

sub update_all ($cb = undef) {
    my $success_all = 1;

    my $cv = P->cv->begin( sub ($cv) { $cv->( $cb ? $cb->($success_all) : $success_all ) } );

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

    return defined wantarray ? $cv->recv : ();
}

sub update ( $type, $cb = undef ) {
    require IO::Uncompress::Gunzip;

    return P->http->get(
        $RES->{$type}->[1],
        mem_buf_size => 0,
        on_progress  => 1,
        sub ($res) {
            my $success = 0;

            if ( $res->{status} == 200 ) {
                eval {
                    my $temp = P->file1->tempfile;

                    IO::Uncompress::Gunzip::gunzip( $res->{data}->{path}, $temp->{path}, BinModeOut => 1 ) or die "gunzip failed: $IO::Uncompress::Gunzip::GunzipError\n";

                    $ENV->{share}->write( "/Pcore-GeoIP/$RES->{$type}->[0]", $temp );

                    # empty cache
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

sub city {
    _get_h($TYPE_CITY) if !exists $H->{$TYPE_CITY};

    return $H->{$TYPE_CITY};
}

sub _get_h ($type) {
    my $path = $ENV->{share}->get( $RES->{$type}->[0] );

    return if !$path;

    require MaxMind::DB::Reader;

    $H->{$type} = MaxMind::DB::Reader->new( file => $path );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 57                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::GeoIP - Maxmind GeoIP wrapper

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
