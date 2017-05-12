package OpenFrame::Example::Redirector;

use strict;
use warnings;

use OpenFrame::Response;
use OpenFrame::Object;
use Pipeline::Segment;
use base qw ( Pipeline::Segment OpenFrame::Object );

sub dispatch {
  my $self  = shift;
  my $store = shift->store();

  my $request = $store->get('OpenFrame::Request');
  return unless $request;

  my $uri     = $request->uri();
  my $path    = $uri->path();
  return unless $path =~ /redirect/;

  # Dead simple, just redirect to the root
  my $response = OpenFrame::Response->new();
  $response->code(ofREDIRECT);
  $response->message("/");
  return $response;
}

1;

__END__

=head1 NAME

OpenFrame::Example::Redirector - Simple redirector

=head1 SYNOPSIS

  my $response = OpenFrame::Example::Redirector->new();

  # (to a pipeline with an OpenFrame::Segment::Apache::Request and
  # some more segments)
  $pipeline->add_segment($response);

=head1 DESCRIPTION

The C<OpenFrame::Example::Redirector> module is a C<Pipeline::Segment>
that redirects any requests for a URL which contains 'redirect' to '/'.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd.
Licensed under the same terms as Perl itself.

=cut


