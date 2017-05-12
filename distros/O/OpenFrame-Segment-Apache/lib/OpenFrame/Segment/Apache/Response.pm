package OpenFrame::Segment::Apache::Response;

use strict;
use warnings;

use Apache;
use Apache::Cookie;
use Apache::Request;
use Apache::Constants qw(:response);
use CGI::Cookie;
use HTTP::Status;
use HTTP::Headers;
use HTTP::Response;
use Pipeline::Segment;
use OpenFrame::Object;
use OpenFrame::Response;

use base qw (Pipeline::Segment OpenFrame::Object);

our $VERSION = '1.02';

sub dispatch {
  my $self  = shift;
  my $store = shift->store();

  $self->emit("being dispatched");

  my $response;

  my $cookies = $store->get('OpenFrame::Cookies');
  $response   = $store->get('OpenFrame::Response');

  if (!$response) {
    $self->emit("no response, making an error");
    ## time to make an error response
    $response = OpenFrame::Response->new();
    $response->code(ofERROR());
    $response->message(
		       q{
			 <h1>There was an error processing your request</h1>
			 <p>No segments produced an OpenFrame::Response object</p>
			}
		      );
    $self->error("no response available");
  }

  if ($response->code == ofDECLINE()) {
    $self->emit("declining");
    return;
  }

  return $self->ofr2httpr($response, $cookies);
}

##
## turns an openframe response to an http response
##
sub ofr2httpr {
  my $self = shift;
  my $ofr  = shift;
  my $cookies = shift;
  my $h;

  my $request = Apache->request;

  my %cookies = $cookies->get_all();

  foreach my $name (keys %cookies) {
    my $value = $cookies{$name}->value;
    $request->err_headers_out->add("Set-Cookie" => $cookies{$name});
  }

  my $status = $self->ofcode2status($ofr);

  $request->no_cache(1);
  $request->status($status);
  $request->header_out("Location" => $ofr->message) if $status == REDIRECT;
  $request->send_http_header( $ofr->mimetype() || 'text/html' );
  $request->print( $ofr->message() );
}

sub ofcode2status {
  my $self = shift;
  my $ofr  = shift;
  my $code = $ofr->code();
  if ($code eq ofOK()) {
    return RC_OK;
  } elsif ($code eq ofREDIRECT()) {
    return REDIRECT;
  } else {
    return RC_INTERNAL_SERVER_ERROR;
  }
}

1;

__END__

=head1 NAME

OpenFrame::Segment::Apache::Response - Apache request segment

=head1 SYNOPSIS

  my $response = OpenFrame::Segment::Apache::Response->new();

  # (to a pipeline with an OpenFrame::Segment::Apache::Request and
  # some more segments)
  $pipeline->add_cleanup($response);

=head1 DESCRIPTION

The OpenFrame::Segment::Apache::Request slot distribution provides a
segment for OpenFrame 3 that converts from OpenFrame::Response objects
into an Apache response. It should be a cleanup segment in the
pipeline.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd.
Licensed under the same terms as Perl itself.

=cut


