use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::StyrOchStall::GetBikeStations;

# ABSTRACT: Get data on all bike stations
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1404';

use XML::Rabbit::Root;
use DateTime::Format::HTTP;
use MooseX::AttributeShortcuts;
use Types::Standard qw/Str/;
use Types::DateTime qw/DateTime/;

has xml => (
    is => 'ro',
    isa => Str,
    required => 1,
);

add_xpath_namespace 'x' => 'TK.DevServer.Services.RentalBikeService';

has_xpath_value _timestamp => '/x:RentalBikes/x:TimeStamp';

has_xpath_object_list stations => '/x:RentalBikes/x:Stations/x:Details' => 'OpenGbg::Service::StyrOchStall::Station',
                                   handles => {
                                        all => 'elements',
                                        count => 'count',
                                        filter => 'grep',
                                        find => 'first',
                                        get_by_index => 'get',
                                        map => 'map',
                                        sort => 'sort',
                                   };

sub get_by_id {
    my $self = shift;
    my $id = shift;

    return $self->find(sub { $_->id == $id });
}

has timestamp => (
    is => 'ro',
    isa => DateTime,
    lazy => 1,
    builder => 1,
);

sub _build_timestamp {
    return DateTime::Format::HTTP->parse_datetime(shift->_timestamp);
}

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::StyrOchStall::GetBikeStations - Get data on all bike stations

=head1 VERSION

Version 0.1404, released 2018-05-19.

=head1 SYNOPSIS

    my $service = OpenGbg->new->styr_och_stall;
    my $stations = $service->get_bike_stations;

    printf 'Time: %s', $stations->timestamp;
    print $stations->get_by_index(5)->to_text;

=head1 METHODS

=head2 timestamp

Returns the timestamp given in the response as a L<DateTime> object.

=head2 all

Returns an array of the L<OpenGbg::Service::StyrOchStall::Station> objects in the response.

=head2 count

Returns the number of L<Station|OpenGbg::Service::StyrOchStall::Station> objects in the response.

=head2 filter(sub { ... })

Allows filtering of the stations. Takes a sub routine reference, into which all L<Station|OpenGbg::Service::StyrOchStall::Station> objects are
passed one-by-one into C<$_>. Works like C<grep>.

=head2 find(sub { ... })

Just like C<filter>, except it returns the first station that matches.

=head2 get_by_index($index)

Returns the n:th L<OpenGbg::Service::StyrOchStall::Station> object in the response.

=head2 get_by_id($id)

Returns the station with id C<$id>.

=head2 map(sub { ... })

Like C<filter> it takes a sub routine reference and passes each L<Station|OpenGbg::Service::StyrOchStall::Station> as C<$_>. Eg, to get a total count of free bikes:

    use List::AllUtils 'sum';
    my $free_bikes_count = sum $response->stations->map( sub { $_->free_bikes });

=head2 sort(sub { ... })

Like C<filter> it takes a sub routine reference. It works just like C<sort> except the two L<Station|OpenGbg::Service::StyrOchStall::Station> objects to compare are passed as C<$_[0]> and C<$_[1]>

    my @most_bikes_first = $response->stations->sort( sub { $_[1]->free_bikes <=> $_[0]->free_bikes });

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
