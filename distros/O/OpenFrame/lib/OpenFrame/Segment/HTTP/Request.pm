package OpenFrame::Segment::HTTP::Request;

use strict;

use CGI;
use Pipeline::Segment;
use OpenFrame::Object;
use OpenFrame::Cookies;
use OpenFrame::Request;
use OpenFrame::Argument::Blob;
use OpenFrame::Segment::HTTP::Response;

use File::Temp qw ( tempfile );

use base qw ( Pipeline::Segment OpenFrame::Object );

our $VERSION=3.05;

sub init {
  my $self = shift;
  $self->respond( 1 );
  $self->SUPER::init( @_ );
}

sub respond {
  my $self = shift;
  my $respond = shift;
  if (defined( $respond )) {
    $self->{respond} = $respond;
    return $self;
  } else {
    return $self->{respond};
  }
}

sub dispatch {
  my $self  = shift;
  my $pipe  = shift;
  
  my $store = $pipe->store();
  
  my $httpr = $store->get('HTTP::Request');

  return undef unless $httpr;

  my ($ofr,$cookies) = $self->req2ofr( $httpr );

  if ($self->respond) {
    return ($ofr, $cookies, OpenFrame::Segment::HTTP::Response->new());
  } else {
    return ($ofr, $cookies);
  }
}

##
## turns an HTTP::Request object into an OpenFrame::Request object
##
sub req2ofr {
  my $self = shift;
  my $r    = shift;
  my $uri  = $r->uri();
  my $args = $self->req2args( $r );
  my $ctin = $self->req2cookie_tin( $r );

  my $ofr  = OpenFrame::Request->new()
                               ->arguments( $args )
			       ->uri( $uri );

  return ($ofr,$ctin);
}

sub req2cookie_tin {
  my $self = shift;
  my $r    = shift;
  my $ctin = OpenFrame::Cookies->new();

  if ($r->header('Cookie')) {
    foreach my $ctext (split(/; ?/, $r->header('Cookie'))) {
      my ($cname, $cvalue) = split /=/, $ctext;
      $ctin->set( $cname, $cvalue );
    }
  }

  return $ctin;
}

sub params2hash {
  my $self = shift;
  my $data = shift;
  my $cgi  = CGI->new($data);
  return {
	  map {
	    my $return;
	    my @results = $cgi->param($_);
	    if (scalar(@results) > 1) {
	      $return = [@results];
	    } else {
	      $return = $results[0];
	    }
	    ($_, $return)
	  } $cgi->param()
	};
}


##
## shameless copied from acme's original
##
sub req2args {
  my $self = shift;
  my $r    = shift;
  my $args = {};

  my $method = $r->method;

  if ($method eq 'GET' || $method eq 'HEAD') {
    $args = $self->params2hash($r->uri->equery);
    $r->uri->query(undef);
  } elsif ($method eq 'POST') {
    my $content_type = $r->content_type;
    if (!$content_type || $content_type eq "application/x-www-form-urlencoded") {
      $args = $self->params2hash($r->content);
      $r->uri->query(undef);
    } elsif ($content_type eq "multipart/form-data") {
      $args = $self->parse_multipart_data($r);
    } else {
      $self->emit("invalid content type: $content_type");
    }
  } else {
    $self->emit("unsupported method: $method");
  }

  return $args;
}

sub parse_multipart_data {
  my $self = shift;
  my $r = shift;
  my $args = {};

  my($boundary) = $r->headers->header("Content-Type") =~ /boundary=(\S+)$/;

  foreach my $part (split(/-?-?$boundary-?-?/, $r->content)) {
    $part =~ s|^\r\n||g;
    next unless $part;
    my %headers;
    my @lines = split /\r\n/, $part;
    while (@lines) {
      my $line = shift @lines;
      last unless $line;
      $headers{type} = $1 if $line =~ /^content-type: (.+)$/i;
      $headers{disposition} = $1 if $line =~ /^content-disposition: (.+)$/i;
    }

    my $name = $1 if $headers{disposition} =~ /name="(.+?)"/;

    if ($headers{disposition} =~ /filename="(.+)?"/) {
      my $filename = $1;


      my $fh = tempfile(DIR => "/tmp/", UNLINK => 1);
      print $fh join("\r\n", @lines);
      $fh->seek(0, 0);
      my $blob = OpenFrame::Argument::Blob->new()
	                                  ->name( $name )
                                          ->filehandle( $fh );

      if ($filename) {
	$blob->filename( $filename );
      }

      $args->{$name} = $blob;
    } else {
      $args->{$name} = join("\n", @lines);
    }
  }

  return $args;
}

1;

=head1 NAME

OpenFrame::Segment::HTTP::Request - creates an OpenFrame::Request object from an HTTP::Request

=head1 SYNOPSIS

  use OpenFrame::Segment::HTTP::Request;
  my $response_creator = OpenFrame::Segment::HTTP::Request->new();
  $pipeline->add_segment( $request );

=head1 DESCRIPTION

OpenFrame::Segment::HTTP::Request inherits from Pipeline::Segment and is used to turn an
HTTP::Request object into an OpenFrame::Request.  Additionally it provides the C<respond()>
method that acts as a get/set method to decide whether or not OpenFrame::Segment::HTTP::Request
places an OpenFrame::Segment::HTTP::Response segment on the pipeline cleanup list.  By default
C<respond()> is set to a true value.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 SEE ALSO

  OpenFrame::Segment::HTTP::Response, Pipeline::Segment

=cut

