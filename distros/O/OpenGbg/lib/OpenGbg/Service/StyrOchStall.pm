use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::StyrOchStall;

# ABSTRACT: Entry point to the StyrOchStall bike rental service
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1403';

use OpenGbg::Elk;
with 'OpenGbg::Service::Getter';

use namespace::autoclean;
use Types::Standard qw/Str/;

use OpenGbg::Service::StyrOchStall::GetBikeStation;
use OpenGbg::Service::StyrOchStall::GetBikeStations;

has handler => (
    is => 'ro',
    required => 1,
);
has service_base => (
    is => 'rw',
    isa => Str,
    default => 'StyrOchStall/v0.1/',
);

sub get_bike_station {
    my $self = shift;
    my $id = shift;

    my $url = "GetBikeStation/$id/%s?";
    my $response = $self->getter($url, 'get_bike_station');

    return OpenGbg::Service::StyrOchStall::GetBikeStation->new(xml => $response);
}

sub get_bike_stations {
    my $self = shift;
    my %args = @_;

    my $geo = '';
    if(exists $args{'lat'} && exists $args{'long'}) {
        my %hash = ( latitude => $args{'lat'}, longitude => $args{'long'}, radius => $args{'radius'} );
        $geo = join '&' => map { "$_=$hash{ $_ }" } keys %hash;
    }

    my $url = "GetBikeStations/%s?$geo&";
    my $response = $self->getter($url, 'get_bike_stations');

    return OpenGbg::Service::StyrOchStall::GetBikeStations->new(xml => $response);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::StyrOchStall - Entry point to the StyrOchStall bike rental service

=head1 VERSION

Version 0.1403, released 2018-03-14.

=head1 SYNOPSIS

    my $service = OpenGbg->new->styr_och_stall;
    my $stations = $service->get_bike_stations;

    print $stations->get_by_index(0)->to_text;

=head1 STATUS

Deprecated. The underlying web service has changed. Nothing under the C<OpenGbg::StyrOchStall> namespace works, and will be replaced.

=head1 DESCRIPTION

Styr och ställ is Gothenburg's bike share program. This service has a couple of methods to get data about the bike stations.

L<Official documentation|http://data.goteborg.se/Pages/Webservice.aspx?ID=10>

See L<OpenGbg> for general information.

=head1 METHODS

=head2 get_bike_station($id)

C<$id> is the station id for the station you want to get information about. You'll need to first have fetched the stations with L<get_bike_stations|/"get_bike_stations(%geography)"> to get the ids.

Returns a L<GetBikeStation|OpenGbg::Service::StyrOchStall::GetBikeStation> object.

=head2 get_bike_stations(%geography)

C<%geography> is an optional hash used to limit returned stations to a geographical area.
Its keys are C<lat> and C<long>, and optionally C<radius> (in metres).

If C<%geography> is absent no geographic filtering is done.

Returns a L<GetBikeStations|OpenGbg::Service::StyrOchStall::GetBikeStations> object.

=head1 EXCEPTIONS

If the http call to the web service fails, a L<BadResponseFromService|OpenGbg::Exception::BadResponseFromService> exception is thrown. Use L<Try::Tiny> to catch.

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
