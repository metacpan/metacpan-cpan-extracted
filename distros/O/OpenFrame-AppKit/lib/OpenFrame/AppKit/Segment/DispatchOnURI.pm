package OpenFrame::AppKit::Segment::DispatchOnURI;

use strict;

use Pipeline::Segment;
use base qw ( Pipeline::Segment );

sub uri {
  my $self = shift;
  my $uri  = shift;
  if (defined($uri)) {
    $self->{_uri} = $uri;
    return $self;
  } else {
    return $self->{_uri};
  }
}

sub dispatch_on_uri {
  my $self = shift;
  my $pipe = shift;
}

sub match_uri {
  my $self = shift;
  my $uri  = shift;
  my $siteUri = $self->uri();
  $uri->path() =~ /^$siteUri/;
}

sub dispatch {
  my $self = shift;
  my $pipe = shift;
  
  my $store = $pipe->store();
  my $req   = $store->get('OpenFrame::Request');

  if ( $self->match_uri( $req->uri() ) ) {
    return ($self->dispatch_on_uri( $pipe ));
  } else {
    return undef;
  }
}

1;

=head1 NAME 

OpenFrame::AppKit::Segment::DispatchOnURI - pipeline segments that dispatch only on certain uris

=head1 SYNOPSIS

  package MyPipeSegment;

  use OpenFrame::AppKit::Segment::DispatchOnURI;
  use base qw(  OpenFrame::AppKit::Segment::DispatchOnURI );
  
  sub uri {
    return qr!/some/uri/here.html!
  }

  sub dispatch_on_uri {
    my $self = shift;
    my $pipe = shift;
    # ...
  }  

  1;

=head1 DESCRIPTION

C<OpenFrame::AppKit::Segment::DispatchOnURI> is a base class for all pipeline segments that want to dispatch
only at a certain uri.  To subclass it you can simply define the dispatch_on_uri method in your package and
call the uri() method, which by default is a get/set for the regular expression that will match the path of
your uri.  If you wish to set a hard value you can override the uri() method to return a regular expression.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd. All Rights Reserved

This code is released under the GNU GPL and Artistic licenses.

=cut

