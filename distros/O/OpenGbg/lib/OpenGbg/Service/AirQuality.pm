use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::AirQuality;

# ABSTRACT: Entry point to the Air Quality service
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1403';

use OpenGbg::Elk;
use namespace::autoclean;
use Types::Standard qw/Str/;

use OpenGbg::Service::AirQuality::GetLatestMeasurement;
use OpenGbg::Service::AirQuality::GetMeasurements;

with 'OpenGbg::Service::Getter';

has handler => (
    is => 'ro',
    required => 1,
);
has service_base => (
    is => 'rw',
    isa => Str,
    default => 'AirQualityService/v1.0/',
);

sub get_latest_measurement {
    my $self = shift;

    my $url = 'LatestMeasurement/%s?';
    my $response = $self->getter($url, 'latest_measurement');

    return OpenGbg::Service::AirQuality::GetLatestMeasurement->new(xml => $response);
}
sub get_measurements {
    my $self = shift;
    my %args = @_;

    my %dates = (startdate => $args{'start'}, enddate => $args{'end'});
    my $dates = join '&' => map { "$_=$dates{ $_ }"} keys %dates;

    my $url = "Measurements/%s?$dates&";
    my $response = $self->getter($url, 'measurements');

    return OpenGbg::Service::AirQuality::GetMeasurements->new(xml => $response);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::AirQuality - Entry point to the Air Quality service

=head1 VERSION

Version 0.1403, released 2018-03-14.

=head1 SYNOPSIS

    my $service = OpenGbg->new->air_quality;
    my $response = $service->get_latest_measurement;

    print $response->measurement->to_text;

=head1 DESCRIPTION

Gothenburg publishes hourly readings on weather and air quality. The service publishes two methods to get this data.

L<Official documentation|http://data.goteborg.se/Pages/Webservice.aspx?ID=13>

See L<OpenGbg> for general information.

=head1 METHODS

=head2 get_latest_measurement

Returns a L<GetLatestMeasurement|OpenGbg::Service::AirQuality::GetLatestMeasurement> object.

=head2 get_measurements(%dates)

C<%dates> is a hash that filters returned measurements. Its keys are C<start> and C<end>, both are expected to be in the iso-8601 representation: C<yyyy-mm-dd>.

Given C<start =E<gt> '2014-10-15', end =E<gt> '2014-10-25'> then all measurements between 2014-10-15 00:00:00 and 2014-10-25 00:00:00 will be returned.

Returns a L<GetMeasurements|OpenGbg::Service::AirQuality::GetMeasurements> object.

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
