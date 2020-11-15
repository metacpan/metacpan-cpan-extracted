package Net::Camera::Sercomm::ICamera2;
use strict;
use warnings;
use base qw{Package::New};
use LWP::UserAgent;
use HTTP::Request;

our $VERSION = '0.01';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Net::Camera::Sercomm::ICamera2 - Perl Interface for Sercomm ICamera2 network camera

=head1 SYNOPSIS

  use Net::Camera::Sercomm::ICamera2;
  my $camera = Net::Camera::Sercomm::ICamera2->new(hostname => 'mycamera.example.com');
  my $jpeg   = $camera->getSnapshot;

=head1 DESCRIPTION

The Sercomm ICamera2 is network camera that can be accessed via a web interface.
This module provides methods to retrieve an image from the camera.

=head1 PROPERTIES

=head2 hostname

Required hostname or IP address

=cut

sub hostname {
  my $self            = shift;
  $self->{'hostname'} = shift if @_;
  die("Error: $PACKAGE property hostname required") unless defined $self->{'hostname'};
  return $self->{'hostname'};
}

=head2 port

TCP/IP port

Default: 80

=cut

sub port {
  my $self        = shift;
  $self->{'port'} = shift if @_;
  $self->{'port'} = 80 unless defined $self->{'port'};;
  return $self->{'port'};
}

=head2 imageSettingsSize

Image size setting passed on the getSnapshot URL.

  size=2 320x240
  size=3 640x480
  size=4 1280x720

Default: 4

All other values return 320x240

=cut

sub imageSettingsSize {
  my $self = shift;
  $self->{'imageSettingsSize'} = shift if @_;
  $self->{'imageSettingsSize'} = 4 unless defined $self->{'imageSettingsSize'};
  return $self->{'imageSettingsSize'};
}

=head2 imageSettingsQuality

Image JPEG compression quality setting passed on the getSnapshot URL.

  quality=1 JPEG quality 85
  quality=2 JPEG quality 70
  quality=3 JPEG quality 55
  quality=4 JPEG quality 40
  quality=5 JPEG quality 25

Default: 1

=cut

sub imageSettingsQuality {
  my $self = shift;
  $self->{'imageSettingsQuality'} = shift if @_;
  $self->{'imageSettingsQuality'} = 1 unless defined $self->{'imageSettingsQuality'};
  return $self->{'imageSettingsQuality'};
}

=head1 METHODS

=head2 getSnapshot

Returns a JPEG image.

=cut

sub getSnapshot {
  my $self     = shift;
  my $ua       = LWP::UserAgent->new; $ua->agent("Mozilla/5.0 (compatible; $PACKAGE/$VERSION; See rt.cpan.org 35173)");
  my $url      = sprintf("http://%s:%s/img/snapshot.cgi?size=%s&quality=%s",
                   $self->hostname, $self->port, $self->imageSettingsSize, $self->imageSettingsQuality);
  my $request  = HTTP::Request->new(GET => $url);
  my $response = $ua->request($request); #isa HTTP::Response
  die(sprintf("HTTP Error: %s", $response->status_line)) unless $response->is_success;
  return $response->content;
}

=head1 SEE ALSO

https://github.com/edent/Sercomm-API, L<Net::Camera::Edimax::IC1500>

=head1 AUTHOR

Michael R. Davis mrdvt at cpan

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Michael R. Davis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;
