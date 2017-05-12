use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::StyrOchStall::GetBikeStation;

# ABSTRACT: Get data about a bike station
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1402';

use XML::Rabbit::Root;
use DateTime::Format::HTTP;
use MooseX::AttributeShortcuts;
use Types::Standard qw/Str/;
use OpenGbg::DateTimeType qw/DateTime/;

has xml => (
    is => 'ro',
    isa => Str,
    required => 1,
);

add_xpath_namespace 'x' => 'TK.DevServer.Services.RentalBikeService';

has_xpath_value _timestamp => '/x:RentalBikes/x:TimeStamp';

has_xpath_object station => '/x:RentalBikes/x:Stations[1]/x:Details' => 'OpenGbg::Service::StyrOchStall::Station',
    handles => [qw/label capacity free_bikes free_stands full empty to_text/];

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

OpenGbg::Service::StyrOchStall::GetBikeStation - Get data about a bike station

=head1 VERSION

Version 0.1402, released 2016-08-12.

=head1 SYNOPSIS

    my $service = OpenGbg->new->styr_och_stall;
    my $station = $service->get_bike_station(1);

    printf 'Time: %s', $response->timestamp;
    print $station->to_text;

=head1 METHODS

All attributes and methods in L<OpenGbg::Service::StyrOchStall::Station> are available on an instance of this class.

=head2 timestamp

Returns the timestamp given in the response as a L<DateTime> object.

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
