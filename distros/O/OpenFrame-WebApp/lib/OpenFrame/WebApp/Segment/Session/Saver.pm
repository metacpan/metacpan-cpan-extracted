=head1 NAME

OpenFrame::WebApp::Segment::Session::Saver - pipeline segment to save sessions

=head1 SYNOPSIS

  # installed automatically in cleanup pipeline
  # by OpenFrame::WebApp::Segment::Session::Loader

=cut

package OpenFrame::WebApp::Segment::Session::Saver;

use strict;
use warnings::register;

our $VERSION = (split(/ /, '$Revision: 1.2 $'))[1];

use base qw( Pipeline::Segment );

sub session {
    my $self = shift;
    if (@_) {
	$self->{session} = shift;
	return $self;
    } else {
	return $self->{session};
    }
}

sub dispatch {
    my $self = shift;
    $self->session->store();
}


1;


__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Segment::Session::Saver> is a session saving segment.
It inherits its interface from C<Pipeline::Segment>.

On dispatch() the session stored.

=head1 METHODS

=over 4

=item session

set/get the C<OpenFrame::WebApp::Session> object.

=item dispatch

dispatch this segment.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

Based on C<OpenFrame::AppKit::Segment::SessionLoader>, by James A. Duncan

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::Session>,
L<OpenFrame::WebApp::Segment::Session::Loader>

=cut
