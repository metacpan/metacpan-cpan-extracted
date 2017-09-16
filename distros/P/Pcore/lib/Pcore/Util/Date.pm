package Pcore::Util::Date;

use Pcore;
use base qw[Time::Moment Pcore::Util::Date::Strptime];

sub parse ( $self, $date ) {
    state $init = do {
        require HTTP::Date;
        require Time::Zone;

        1;
    };

    if ( my @http_date = HTTP::Date::parse_date($date) ) {
        my %args = (    #
            year       => $http_date[0],
            month      => $http_date[1],
            day        => $http_date[2],
            hour       => $http_date[3],
            minute     => $http_date[4],
            second     => $http_date[5],
            nanosecond => 0,
        );

        if ( defined $http_date[6] ) {
            my $offset = Time::Zone::tz_offset( $http_date[6] );

            # invalid offset
            die qq[Invalid date offset "$http_date[6]"] if !defined $offset;

            $args{offset} = $offset / 60;
        }

        return $self->new(%args);
    }
    else {
        return;
    }
}

# %a, %d %b %Y %H:%M:%S %z
sub to_rfc_1123 ($self) {
    return $self->strftime('%a, %d %b %Y %H:%M:%S %z');
}

*to_http_date = \&to_rfc_2616;

# %a, %d %b %Y %H:%M:%S GMT
sub to_rfc_2616 ($self) {
    return $self->at_utc->strftime('%a, %d %b %Y %H:%M:%S GMT');
}

# %Y-%m-%dT%H:%M:%S%Z
sub to_w3cdtf ($self) {
    return $self->strftime('%Y-%m-%dT%H:%M:%S%Z');
}

sub duration ( $self, $start, $end ) {
    state $init = !!require Pcore::Util::Date::Duration;

    return Pcore::Util::Date::Duration->new( { start => $start, end => $end } );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Date

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
