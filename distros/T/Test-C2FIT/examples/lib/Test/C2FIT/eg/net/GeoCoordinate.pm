# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl port by Martin Busik <martin.busik@busik.de>
#
# GeoCoordinate implements both the value object and the appropriate TypeAdapter
#

package Test::C2FIT::eg::net::GeoCoordinate;
use base 'Test::C2FIT::TypeAdapter';

sub new {
    my $pkg = shift;
    my $self = bless $pkg->SUPER::new(@_), $pkg;
    $self->{lat} = undef;
    $self->{lon} = undef;
    return $self;
}

sub parse {
    my $self  = shift;
    my $value = uc(shift);
    my $coord;

    if (
        $value =~ /^\s* ([NS]) (\d{1,3}(?:\.\d{1,2}))
                   \s+ ([WE]) (\d{1,3}(?:\.\d{1,2})) \s*$/xi
      )
    {

        #
        #   canonical form
        #
        $coord = {
            lat => $2 * ( ( $1 eq 'N' ) ? 1 : -1 ),
            lon => $4 * ( ( $3 eq 'E' ) ? 1 : -1 )
        };

    }
    elsif (
        $value =~ /^\s* (\d{1,3}) \s (\d{1,2}(?:\.\d\d?)?) \s ([NS])
                         \s+ (\d{1,3}) \s (\d{1,2}(?:\.\d\d?)?) \s ([WE]) \s*$/xi
      )
    {

        #
        #   convert to canonical
        #
        my $ns  = $3;
        my $we  = $6;
        my $lat = ( $1 + $2 / 60 ) * ( ( $ns eq 'N' ) ? 1 : -1 );
        my $lon = ( $4 + $5 / 60 ) * ( ( $we eq 'E' ) ? 1 : -1 );

        $coord = { lat => $lat, lon => $lon };

    }
    elsif (
        $value =~ /^\s* (\d{1,3}) \s (\d\d?)' \s (\d\d?)" \s* ([NS])
                         \s+ (\d{1,3}) \s (\d\d?)' \s (\d\d?)" \s* ([WE]) \s*$/xi
      )
    {
        my $ns  = $4;
        my $we  = $8;
        my $lat = ( $1 + $2 / 60 + $3 / 3600 ) * ( ( $ns =~ /N/i ) ? 1 : -1 );
        my $lon = ( $5 + $6 / 60 + $7 / 3600 ) * ( ( $we =~ /E/i ) ? 1 : -1 );
        $coord = { lat => $lat, lon => $lon };

    }
    else {
        die "unknown format! $value\n";
    }
    return bless $coord, ref($self);
}

sub toString {
    my $self = shift;
    my $ns   = ( $self->{lat} < 0 ) ? 'S' : 'N';
    my $we   = ( $self->{lon} < 0 ) ? 'W' : 'E';
    my $lat  = abs( $c->{lat} );
    my $lon  = abs( $c->{lon} );

    return "$ns$lat $we$lon";
}

1;
