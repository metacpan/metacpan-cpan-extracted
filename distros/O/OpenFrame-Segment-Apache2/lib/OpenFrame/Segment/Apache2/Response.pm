package OpenFrame::Segment::Apache2::Response;

use strict;
use warnings;

use Apache2;
use Apache::Response;
use HTTP::Response;
use Pipeline::Segment;
use OpenFrame::Object;
use OpenFrame::Response;

use base qw (Pipeline::Segment OpenFrame::Object);

our $VERSION = '1.00';

sub dispatch {
  my($self, $pipeline) = @_;
  my $store = $pipeline->store();

  $self->emit("being dispatched");

  my $cookies  = $store->get('OpenFrame::Cookies');
  my $response = $store->get('OpenFrame::Response');

  if (not defined $response) {
    $self->emit("no response, making an error");
    ## time to make an error response
    $response = OpenFrame::Response->new();
    $response->code(ofERROR());
    $response->message(q{
<html><head><title>Error</title></head><body>
<h1>There was an error processing your request</h1>
<p>No segments produced an OpenFrame::Response object</p>
</body></html>
			});
    $self->error("no response available");
  }

  if ($response->code == ofDECLINE()) {
    $self->emit("declining");
    return;
  }

  return $self->output_response($response, $cookies, $store);
}

##
## outputs the response
##
sub output_response {
  my($self, $ofr, $cookies, $store) = @_;
  my $r = $store->get('Apache::RequestRec');

  my %cookies = $cookies->get_all();
  foreach my $name (keys %cookies) {
    $r->err_headers_out->add("Set-Cookie" => $cookies{$name});
  }

  my $code = $ofr->code;
  my $message = $ofr->message;
  my $mimetype = $ofr->mimetype || 'text/html';
  if ($code eq ofOK()) {
    $r->no_cache(1);
    $r->content_type($mimetype);
    $r->status(200);
    $r->print($ofr->message);
  } elsif ($code eq ofREDIRECT()) {
    $r->headers_out->{Location} = $message;
    $r->status(302);
    $r->print($message);
  } else {
    $r->print($message);
  }

  return 1;
}

__END__

=head1 NAME

OpenFrame::Segment::Apache2::Response - Apache2 request segment

=head1 SYNOPSIS

  my $response = OpenFrame::Segment::Apache2::Response->new();

  # (to a pipeline with an OpenFrame::Segment::Apache2::Request and
  # some more segments)
  $pipeline->add_cleanup($response);

=head1 DESCRIPTION

The OpenFrame::Segment::Apache2::Request slot distribution provides a
segment for OpenFrame 3 that converts from OpenFrame::Response objects
into an Apache2 response. It should be a cleanup segment in the
pipeline.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd.
Licensed under the same terms as Perl itself.

=cut


