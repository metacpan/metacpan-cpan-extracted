package OpenFrame::Segment::Apache2;
use strict;
use OpenFrame::Segment::Apache2::Request;
use OpenFrame::Segment::Apache2::Response;

our $VERSION = '1.00';

1;

__END__

=head1 NAME

OpenFrame::Segment::Apache2 - Apache2 segments for OpenFrame 3

=head1 SYNOPSIS

  # tricky to explain, but mostly:
  PerlHandler YourHandler

=head1 DESCRIPTION

The OpenFrame::Segment::Apache2 distribution provides segments for
OpenFrame 3 that convert from Apache2 requests to OpenFrame::Request
objects and from OpenFrame::Response objects to produce an Apache2
response.

It will be demonstrated with a simple OpenFrame example which simply
loads static content, OpenFrame::Example::Apache2Simple.

The following configuration should be in httpd.conf:

  SetHandler  perl-script
  PerlSetVar  cwd /home/website/
  PerlHandler OpenFrame::Example::Apache2Simple

The actual handler is quite short. The important part is to set up a
pipeline which has a OpenFrame::Segment::Apache2::Request segment at
the beginning and a OpenFrame::Segment::Apache2::Response as a cleanup
segment.

Note that there is also a C<OpenFrame::Segment::Apache2::NoImages> which
declines and lets Apache2 serve images.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd.
Licensed under the same terms as Perl itself.

=cut

