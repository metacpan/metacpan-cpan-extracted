package OpenFrame::AppKit::Segment::SessionLoader;

use strict;
use warnings::register;

use Pipeline::Segment;
use OpenFrame::Cookie;
use OpenFrame::Cookies;
use OpenFrame::AppKit::Session;

our $VERSION=3.03;

use base qw ( Pipeline::Segment );

sub dispatch {
  my $self = shift;
  my $pipe = shift;

  my ($session, $id);
 
  ## get the cookie container
  my $cookies = $pipe->store->get('OpenFrame::Cookies');
  ## get the session cookie
  if ( $cookies ) {
    my $scookie = $cookies->get('session');
    ## get the value of the session cookie
    $id = $scookie->value() if $scookie;
  } else {
    $pipe->store->set( OpenFrame::Cookies->new() );
  }

  ## if all that has left us with an id, we have a session to fetch
  if ($id) {
    $session = OpenFrame::AppKit::Session->fetch( $id );
  }

  ## if we still don't have a session...
  if (!$session) {
    ## create a new session
    $session = OpenFrame::AppKit::Session->new();

    ## create a cookie to keep track on the client side
    my $cookie = OpenFrame::Cookie->new();    
    $cookie->name('session');
    $cookie->value( [ $session->id ] );
    $pipe->store->get('OpenFrame::Cookies')->set( $cookie );
  }

  return (
	  $session,
	  OpenFrame::AppKit::Segment::SessionSaver->new()
                                                  ->session( $session )
	 );
}

package OpenFrame::AppKit::Segment::SessionSaver;

use strict;
use warnings::register;

use Pipeline::Segment;
use base qw ( Pipeline::Segment );

sub dispatch {
  my $self = shift;
  $self->session->store();
}

sub session {
  my $self = shift;
  my $sess = shift;
  if (defined($sess)) {
    $self->{session} = $sess;
    return $self;
  } else {
    return $self->{session};
  }
}

1;


=head1 NAME

OpenFrame::AppKit::Segment::SessionLoader - a pipeline segment to manage sessions

=head1 SYNOPSIS

  use OpenFrame::AppKit;
  my $session_loader = OpenFrame::Segment::SessionLoader->new();

=head1 DESCRIPTION

The C<OpenFrame::AppKit::Segment::SessionLoader> class is a pipeline segment and inherits its
interface from there.  It manages OpenFrame::AppKit::Session objects.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd. All Rights Reserved

This program is released under the same license as Perl itself.
