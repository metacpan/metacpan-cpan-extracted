use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::TrafficCamera::CameraDevice;

# ABSTRACT: Data about a traffic camera
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1404';

use XML::Rabbit;
use syntax 'qs';
use utf8;

has_xpath_value id => './x:ID';

has_xpath_value storage_duration_minutes => './x:StorageDurationMinutes';

has_xpath_value capture_interval_seconds => './x:CaptureIntervalSeconds';

has_xpath_value description => './x:Description';

has_xpath_value model => './x:Model';

has_xpath_value lat => './x:Lat';

has_xpath_value long => './x:Long';

sub get_latest_image {
    my $self = shift;

    return OpenGbg->new->traffic_camera->get_camera_image($self->id);
}

sub to_text {
    my $self = shift;

    return sprintf qs{
                Id:                    %s
                Description:           %s
                Storage duration (m):  %s
                Capture interval (s):  %s
                Model:                 %s
                Lat:                   %s
                Long:                  %s
            },
            $self->id,
            $self->description,
            $self->storage_duration_minutes,
            $self->capture_interval_seconds,
            $self->model,
            $self->lat,
            $self->long;

}

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::TrafficCamera::CameraDevice - Data about a traffic camera

=head1 VERSION

Version 0.1404, released 2018-05-19.

=head1 SYNOPSIS

    my $traffic_camera_service = OpenGbg->new->traffic_camera;
    my $get_traffic_cameras = $traffic_camera_service->get_traffic_cameras;

    my $camera_devices = $get_traffic_cameras->camera_devices;
    my $camera_device = $camera_devices->get_by_index(0)
    print $camera_device->to_text;

=head1 ATTRIBUTES

=head2 id

Integer. The traffic camera id.

=head2 description

String. The description/location of the traffic camera.

=head2 storage_duration_minutes

Integer. How long is the image saved. There is however currently no service to get any image but the latest.

=head2 capture_interval_seconds

Integer. How long between captures.

=head2 model

String. The brand and/or model of the traffic camera.

=head2 lat

Decimal. The latitude location of the camera.

=head2 long

Decimal. The longitude location of the camera.

=head1 METHODS

=head2 get_latest_image

Returns the latest available image from the camera.

=head2 to_text()

Returns a string with the traffic camera data in a table.

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
