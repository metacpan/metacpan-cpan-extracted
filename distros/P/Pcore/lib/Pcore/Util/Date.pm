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

*to_http_date = *to_rfc2616 = \&to_rfc7231;

*to_w3cdtf = \&to_iso8601;

# Wed, 09 Feb 94 22:23:32 -0100, two digits year
sub to_rfc822 ($self) {
    return $self->strftime('%a, %d %b %y %H:%M:%S %z');
}

# Wed, 09 Feb 1994 22:23:32 -0100, RFC 822 + 4 digits year
sub to_rfc1123 ($self) {
    return $self->strftime('%a, %d %b %Y %H:%M:%S %z');
}

# Wed, 09 Feb 1994 22:23:32 GMT, RFC 1123 + always in UTC zone
sub to_rfc7231 ($self) {
    return $self->at_utc->strftime('%a, %d %b %Y %H:%M:%S GMT');
}

# 2019-12-30T24:60:60Z
sub to_iso8601 ($self) {
    return $self->strftime('%Y-%m-%dT%H:%M:%S%Z');
}

# 20190130T241260Z
sub to_iso8601_compact ($self) {
    return $self->strftime('%Y%m%dT%H%M%S%Z');
}

sub duration ( $self, $start, $end ) {
    require Pcore::Util::Date::Duration;

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
