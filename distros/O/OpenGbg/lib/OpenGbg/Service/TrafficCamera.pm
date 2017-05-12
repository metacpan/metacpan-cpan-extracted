use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::TrafficCamera;

# ABSTRACT: Entry point to the Traffic Camera service
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1402';

use OpenGbg::Elk;

use namespace::autoclean;
use Types::Standard qw/Str/;

use OpenGbg::Service::TrafficCamera::GetCameraImage;
use OpenGbg::Service::TrafficCamera::GetTrafficCameras;
with 'OpenGbg::Service::Getter';

has handler => (
    is => 'ro',
    required => 1,
);
has service_base => (
    is => 'rw',
    isa => Str,
    default => 'TrafficCamera/v0.1/',
);

sub get_camera_image {
    my $self = shift;
    my $id = shift;

    my $url = "CameraImage/%s/$id?";
    my $response = $self->getter($url, 'get_camera_image');

    return OpenGbg::Service::TrafficCamera::GetCameraImage->new(image => $response);
}

sub get_traffic_cameras {
    my $self = shift;

    my $url = 'TrafficCameras/%s?';
    my $response = $self->getter($url, 'get_traffic_cameras');

    return OpenGbg::Service::TrafficCamera::GetTrafficCameras->new(xml => $response);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::TrafficCamera - Entry point to the Traffic Camera service

=head1 VERSION

Version 0.1402, released 2016-08-12.

=head1 SYNOPSIS

    my $traffic_camera_service = OpenGbg->new->traffic_camera;
    my $response = $traffic_camera_service->get_traffic_cameras;

    print $response->camera_devices->get_by_index(0)->to_text;

=head1 DESCRIPTION

Traffic cameras all around Gothenburg captures a lot of images (usually once per minute). This service gives information about the
cameras themselves, as well as a way to get the latest captured image from all cameras.

L<Official documentation|http://data.goteborg.se/Pages/Webservice.aspx?ID=15>

See L<OpenGbg> for general information.

=head1 METHODS

=head2 get_traffic_cameras

Get information on the traffic cameras.

Returns a L<GetTrafficCameras|OpenGbg::Service::TrafficCamera::GetTrafficCameras> object.

=head2 get_camera_image($camera_id)

Get the latest image from the camera with id C<$id>.

Returns a L<GetCameraImage|OpenGbg::Service::TrafficCamera::GetCameraImage> object.

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
