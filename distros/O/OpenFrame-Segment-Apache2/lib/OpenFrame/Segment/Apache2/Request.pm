package OpenFrame::Segment::Apache2::Request;

use strict;
use warnings;

use Apache2;
use Apache::Const;
use Apache::URI;
use CGI::Cookie;
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
  $self->SUPER::init( @_ );
}

sub dispatch {
  my $self  = shift;
  my $store = shift->store();

  $self->emit("being dispatched");

  my $r = $store->get('Apache::RequestRec');

  my ($ofr, $cookies) = $self->req2ofr($r);
  $self->emit("uri is " . $ofr->uri);

  $self->emit("dispatched and responding");
  return ($ofr, $cookies, OpenFrame::Segment::HTTP::Response->new());

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
#  my $uri = URI->new(Apache::URI->parse_uri($r)->unparse);
  my $uri = URI->new($r->uri); # for now!

  my $ofr  = OpenFrame::Request->new()
                               ->arguments($args)
			       ->uri($uri);

  return ($ofr,$ctin);
}

sub req2ctin {
  my($self, $r) = @_;
  my $cookietin = OpenFrame::Cookies->new();

  my %cookies = CGI::Cookie->parse($r->headers_in->{Cookie});
  foreach my $key (keys %cookies) {
    $cookietin->set($key, $cookies{$key}->value);
  }

  return $cookietin;
}

sub req2args {
  my($self, $r) = @_;

  my @args = map {
    tr/+/ /;
    s/%([0-9a-fA-F]{2})/pack("C",hex($1))/ge;
    $_;
  } split /[=&;]/, $r->args, -1;

  my %args = @args;
  return \%args;

warn join(", ", @args);

#  my %args;
#  my $args = {
#              map {
#                   my $return;
#                   my @results = $ar->param($_);
#                   if (scalar(@results) > 1) {
#                     $return = [@results];
#                   } else {
#                     $return = $results[0];
#                   }
#                   ($_, $return)
#                  } @args
#            };


# DON'T DO UPLOADS YET!
#
#  foreach my $upload ( $ar->upload ) {
#    my $name = $upload->name;
#    my $filename = $upload->filename;
#    my $fh = $upload->fh;
#    my $blob = OpenFrame::Argument::Blob->new();
#    $blob->name($name);
#    $blob->filehandle($fh);
#    $blob->filename($filename) if $filename;
#    $args->{$name} = $blob;
#  }

  return {};
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


