use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::StyrOchStall::Station;

# ABSTRACT: Data on a bike station
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1402';

use XML::Rabbit;
use syntax 'qs';

has_xpath_value id => './x:Id';
has_xpath_value original_label => './x:Label';
has_xpath_value lat => './x:Lat';
has_xpath_value long => './x:Long';
has_xpath_value _capacity => './x:Capacity';
has_xpath_value _free_bikes => './x:FreeBikes';
has_xpath_value _free_stands => './x:FreeStands';
has_xpath_value state => './x:State';

sub label {
    my $self = shift;

    my $label = $self->original_label;
    $label =~ s{([\w']+)}{\u\L$1}g;
    return $label;
}

sub capacity {
    my $self = shift;

    return length $self->_capacity ? $self->_capacity : 0;
}
sub free_bikes {
    my $self = shift;

    return length $self->_free_bikes ? $self->_free_bikes : 0;
}
sub free_stands {
    my $self = shift;

    return length $self->_free_stands ? $self->_free_stands : 0;
}
sub full {
    my $self = shift;

    return $self->free_stands == 0;
}
sub empty {
    my $self = shift;

    return $self->free_bikes == 0;
}

sub to_text {
    my $self = shift;

    return sprintf qs{
                Id:             %s
                Label:          %s
                Latitude:       %s
                Longitude:      %s
                Capacity:       %2d
                Free bikes:     %2d
                Free stands:    %2d
                Empty:          %s
                Full:           %s
                State:          %s
            },
            $self->id,
            $self->label,
            $self->lat,
            $self->long,
            $self->capacity,
            $self->free_bikes,
            $self->free_stands,
            $self->empty,
            $self->full,
            $self->state;
}

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::StyrOchStall::Station - Data on a bike station

=head1 VERSION

Version 0.1402, released 2016-08-12.

=head1 SYNOPSIS

    my $service = OpenGbg->new->styr_och_stall;
    my $station = $service->get_bike_stations->get_by_index(2);

    printf 'Free bikes:  %d', $station->free_bikes;

=head1 ATTRIBUTES

=head2 id

Integer. The station id.

=head2 label

String. The station/location name.

=head2 lat

=head2 long

Decimal degrees. The location of the station.

=head2 capacity

Integer. Maximum number of bikes.

=head2 free_bikes

Integer. Number of available bikes.

=head2 free_stands

Integer. Number of open stands.

=head2 state

String. Can be C<open>, C<closed>, C<maintenance> or C<construction>.

=head2 empty

Boolean. Returns true if there is no bike available.

=head2 full

Boolean. Returns true if there is no room to return a bike to.

=head1 METHODS

=head2 to_text()

Returns a string with the station data in a table.

=head1 SOURCE

L<https://github.com/Csson/p5-OpenGbg>

=head1 HOMEPAGE

L<https://metacpan.org/release/OpenGbg>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
