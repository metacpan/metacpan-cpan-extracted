use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::AirQuality::GetMeasurements;

# ABSTRACT: Get a collection of measurements
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1404';

use XML::Rabbit::Root;
use MooseX::AttributeShortcuts;
use Types::Standard qw/Str/;

has xml => (
    is => 'ro',
    isa => Str,
    required => 1,
);

add_xpath_namespace 'x' => 'TK.DevServer.Services.AirQualityService';

has_xpath_object measurements => '/x:Measurements' => 'OpenGbg::Service::AirQuality::Measurements';

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::AirQuality::GetMeasurements - Get a collection of measurements

=head1 VERSION

Version 0.1404, released 2018-05-19.

=head1 NAME

OpenGbg::Service::AirQuality::GetMeasurements

=head1 SYNOPSIS

    my $service = OpenGbg->new->air_quality;
    my $response = $service->get_measurements(start => '2014-10-15', end => '2014-10-25');

    print $response->measurements->get_by_index(5)->to_text;

=head1 METHODS

=head2 measurements

Returns the list of measurements in the response in a L<OpenGbg::Service::AirQuality::Measurements> object.

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
