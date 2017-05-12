package OpenFrame::Segment::Apache;
use strict;
use OpenFrame::Segment::Apache::Request;
use OpenFrame::Segment::Apache::Response;

our $VERSION = '1.20';

1;

__END__

=head1 NAME

OpenFrame::Segment::Apache - Apache segments for OpenFrame 3

=head1 SYNOPSIS

  # tricky to explain, but mostly:
  PerlHandler YourHandler

=head1 DESCRIPTION

The OpenFrame::Segment::Apache distribution provides segments for
OpenFrame 3 that convert from Apache requests to OpenFrame::Request
objects and from OpenFrame::Response objects to produce an Apache
response.

It will be demonstrated with a simple OpenFrame example which simply
loads static content, OpenFrame::Example::ApacheSimple.

The following configuration should be in httpd.conf:

  SetHandler  perl-script
  PerlSetVar  cwd /home/website/
  # PerlSetVar  debug 1
  PerlHandler OpenFrame::Example::ApacheSimple

The actual handler is quite short. The important part is to set up a
pipeline which has a OpenFrame::Segment::Apache::Request segment at
the beginning and a OpenFrame::Segment::Apache::Response as a cleanup
segment.

Note that there is also a C<OpenFrame::Segment::Apache::NoImages> which
declines and lets Apache serve images.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd.
Licensed under the same terms as Perl itself.

=cut

