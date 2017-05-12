package OpenFrame::Segment::HTTP::Response;

use strict;

#no strict 'subs';

use warnings::register;

use CGI::Cookie;
use HTTP::Status;
use HTTP::Headers;
use HTTP::Response;
use Pipeline::Segment;
use OpenFrame::Object;
use OpenFrame::Response;

use base qw ( Pipeline::Segment OpenFrame::Object );

our $VERSION=3.05;

sub dispatch {
  my $self  = shift;
  my $store = shift->store();

  my $response;

  my $cookies = $store->get( 'OpenFrame::Cookies' );
  $response   = $store->get( 'OpenFrame::Response' );

  if (!$response) {
    ## time to make an error response
    $response = OpenFrame::Response->new();
    $response->code( ofERROR() );
    $response->message(
		       q{
			 <h1>There was an error processing your request</h1>
			 <p>No segments produced an OpenFrame::Response object</p>
			}
		      );
    $self->error("no response available");
  }

  return $self->ofr2httpr( $response, $cookies );
}

##
## turns an openframe response to an http response
##
sub ofr2httpr {
  my $self = shift;
  my $ofr  = shift;
  my $cookies = shift;
  my $h;

  if ( defined( $cookies ) ) {
    my %cookies = $cookies->get_all();
    $h = HTTP::Headers->new();
    $h->header('Set-Cookie' => [values(%cookies)]);
  }

  my $status = $self->ofcode2status( $ofr );
  if ($status eq RC_FOUND) {
    $h->header('Location' => $ofr->message());
  }

  my $mesg = HTTP::Response->new(
				 $status,
				 undef,
				 $h,
				 $ofr->message(),
				);

  $mesg->content_type( $ofr->mimetype || "text/html" );

  return $mesg;
}

sub ofcode2status {
  my $self = shift;
  my $ofr  = shift;
  if ($ofr->code() eq ofOK()) {
    return RC_OK;
  } elsif ($ofr->code() eq ofREDIRECT()) {
    return RC_FOUND;
  } else {
    return RC_INTERNAL_SERVER_ERROR;
  }
}

1;

=head1 NAME

OpenFrame::Segment::HTTP::Response - creates an HTTP::Response object from an OpenFrame::Response

=head1 SYNOPSIS

  use OpenFrame::Segment::HTTP::Response;
  my $response_creator = OpenFrame::Segment::HTTP::Response->new();
  $pipeline->add_segment( $response );

=head1 DESCRIPTION

OpenFrame::Segment::HTTP::Response inherits from Pipeline::Segment and is used to turn an
OpenFrame::Response object into an HTTP::Response.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 SEE ALSO

  OpenFrame::Segment::HTTP::Request, Pipeline::Segment

=cut










