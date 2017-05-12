package OpenFrame::Segment::Apache::Request;

use strict;
use warnings;

use Apache;
use Apache::Cookie;
use Apache::Request;
use Apache::Constants qw ( :response );
use Apache::URI;
use OpenFrame::Argument::Blob;
use OpenFrame::Object;
use OpenFrame::Cookies;
use OpenFrame::Request;
use OpenFrame::Segment::HTTP::Response;
use Pipeline::Segment;
use Scalar::Util qw ( blessed );
use URI;

our $VERSION = '1.02';

use base qw(Pipeline::Segment OpenFrame::Object);

sub init {
  my $self = shift;
  $self->emit("initialising");
  $self->respond(0);
  $self->SUPER::init( @_ );
}

sub respond {
  my $self = shift;
  my $respond = shift;
  if (defined $respond) {
    $self->{respond} = $respond;
    return $self;
  } else {
    return $self->{respond};
  }
}

sub dispatch {
  my $self  = shift;
  my $store = shift->store();

  $self->emit("being dispatched");

  my $r = Apache->request();

  my ($ofr, $cookies) = $self->req2ofr($r);
  $self->emit("uri is " . $ofr->uri);

  if ($self->respond) {
    $self->emit("dispatched and responding");
    return ($ofr, $cookies, OpenFrame::Segment::HTTP::Response->new());
  } else {
    $self->emit("dispatched and not responding");
    return ($ofr, $cookies);
  }
}

##
## turns an Apache::Request object into an OpenFrame::Request object
##
sub req2ofr {
  my $self = shift;
  my $r    = shift;
  my $args = $self->req2args($r);
  my $ctin = $self->req2ctin($r);

  # hmmm, unfortunately Apache doesn't support $r->scheme so
  # we have to use Apache::URI
  my $uri = URI->new(Apache::URI->parse($r)->unparse);

  my $ofr  = OpenFrame::Request->new()
                               ->arguments($args)
			       ->uri($uri);

  return ($ofr,$ctin);
}

sub req2ctin {
  my $self = shift;
  my $r    = shift;
  my $cookietin = OpenFrame::Cookies->new();

  my $ar = Apache::Request->new($r);
  my %apcookies  = Apache::Cookie->fetch();

  foreach my $key (keys %apcookies) {
    $cookietin->set($apcookies{$key}->name(), $apcookies{$key}->value());
  }

  return $cookietin;
}

sub req2args {
  my $self = shift;
  my $r    = shift;
  my $ar = Apache::Request->new($r);

  my $args = {
              map {
                   my $return;
                   my @results = $ar->param($_);
                   if (scalar(@results) > 1) {
                     $return = [@results];
                   } else {
                     $return = $results[0];
                   }
                   ($_, $return)
                  } $ar->param()
            };



  foreach my $upload ( $ar->upload ) {
    my $name = $upload->name;
    my $filename = $upload->filename;
    my $fh = $upload->fh;
    my $blob = OpenFrame::Argument::Blob->new();
    $blob->name($name);
    $blob->filehandle($fh);
    $blob->filename($filename) if $filename;
    $args->{$name} = $blob;
  }

  return $args;
}

1;

__END__

=head1 NAME

OpenFrame::Segment::Apache::Request - Apache request segment

=head1 SYNOPSIS

  my $request = OpenFrame::Segment::Apache::Request->new();
  my $pipeline = Pipeline->new();
  $pipeline->add_segment($request);
  # add more segments here

=head1 DESCRIPTION

The OpenFrame::Segment::Apache::Request slot distribution provides a
segment for OpenFrame 3 that converts from Apache requests to
OpenFrame::Request objects. It should be the first segment in the
pipeline.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd.
Licensed under the same terms as Perl itself.

=cut


