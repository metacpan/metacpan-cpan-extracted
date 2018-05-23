use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::TrafficCamera::GetTrafficCameras;

# ABSTRACT: Get a list of traffic cameras
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1404';

use XML::Rabbit::Root;
use Types::Standard qw/Str/;


has xml => (
    is => 'ro',
    isa => Str,
    required => 1,
);

add_xpath_namespace 'x' => 'TK.DevServer.Services.TrafficCameras';

has_xpath_object camera_devices => '/x:CameraDevices' => 'OpenGbg::Service::TrafficCamera::CameraDevices';

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::TrafficCamera::GetTrafficCameras - Get a list of traffic cameras

=head1 VERSION

Version 0.1404, released 2018-05-19.

=head1 SYNOPSIS

    my $traffic_camera_service = OpenGbg->new->traffic_camera;
    my $get_traffic_cameras = $traffic_camera_service->get_traffic_cameras;

    print $get_traffic_cameras->camera_devices->get_by_index(0)->to_text;

=head1 METHODS

=head2 camera_devices

Returns the list of traffic cameras in the response in a L<OpenGbg::Service::TrafficCamera::CameraDevices> object.

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
