=head1 NAME

OpenFrame::WebApp::Segment::Session::Loader - abstract pipeline segment to load
sessions

=head1 SYNOPSIS

  # abstract class - cannot be used directly

  use Pipeline;
  use OpenFrame::WebApp;

  my $pipe = new Pipeline;

  my $sfactory = new OpenFrame::WebApp::Session::Factory()->type('mem_cache');
  $pipe->store->set( $sfactory );

  # abstract - must use a sub-class:
  my $sloader = new OpenFrame::WebApp::Segment::Session::CookieLoader;
  $pipe->add_segment( $sloader );

  ...

  $pipe->dispatch;

=cut

package OpenFrame::WebApp::Segment::Session::Loader;

use strict;
use warnings::register;

use Error;
use OpenFrame::WebApp::Error::Abstract;
use OpenFrame::WebApp::Session;
use OpenFrame::WebApp::Session::Factory;
use OpenFrame::WebApp::Segment::Session::Saver;

our $VERSION = (split(/ /, '$Revision: 1.6 $'))[1];

use base qw( Pipeline::Segment );


sub dispatch {
    my $self      = shift;
    my $pipe      = shift;
    my $session   = $self->get_session();
    my $saver_seg = $self->create_saver_segment( $session );
    return( $session, $saver_seg );
}

sub get_session {
    my $self     = shift;
    my $sfactory = $self->store->get('OpenFrame::WebApp::Session::Factory');
    my $session;

    if (my $id = $self->find_session_id) {
	$session = $sfactory->fetch_session( $id );
    }
    unless ($session) {
	$session = $sfactory->new_session();
    }

    return $session;
}

sub create_saver_segment {
    my $self    = shift;
    my $session = shift;
    new OpenFrame::WebApp::Segment::Session::Saver()->session( $session );
}

sub find_session_id {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}


1;


__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Segment::Session::Loader> class is an abstract session
loading segment.  It inherits its interface from C<Pipeline::Segment>.

On dispatch() a session is fetched or created using the Pipeline's stored
C<OpenFrame::WebApp::Session::Factory>, and a new
C<OpenFrame::WebApp::Segment::Session::Saver> object is added to the cleanup
pipeline so that any modifications to the session will be saved for the next
request.

=item METHODS

=over 4

=item dispatch

dispatch this segment.

=item $session = $obj->get_session

looks for session id with find_session_id(), and creates/fetches the
session using C<OpenFrame::WebApp::Session::Factory>.

=item $seg = $obj->create_saver_segment( $session )

returns a new C<OpenFrame::WebApp::Segment::Session::Saver> object for this
$session.

=item $id = $obj->find_session_id

I<abstract> method for finding the session id.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

Based on C<OpenFrame::AppKit::Segment::SessionLoader>, by James A. Duncan

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Pipeline::Segment>,
L<OpenFrame::WebApp::Session>,
L<OpenFrame::WebApp::Segment::Session::Saver>,
L<OpenFrame::WebApp::Segment::Session::CookieLoader>

=cut
