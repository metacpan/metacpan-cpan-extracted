=head1 NAME

OpenFrame::WebApp::Segment::Decline - abstract class for declining to process a
pipeline.

=head1 SYNOPSIS

  # abstract class - cannot be used directly

  use Pipeline;
  use OpenFrame::WebApp::Segment::Decline::Something;

  my $sub_pipe = new Pipeline;

  my $decliner = new OpenFrame::WebApp::Segment::Decline::Something;
  $sub_pipe->add_segment( $decliner, ... );

  my $pipe = new Pipeline;
  $pipe->add_segment( ..., $sub_pipe, ... );

  ...

  $pipe->dispatch;

  # sub_pipe will not be executed if Decline::Something's
  # should_decline is true.

=cut

package OpenFrame::WebApp::Segment::Decline;

use strict;
use warnings::register;

use Pipeline::Production;
use OpenFrame::WebApp::Error::Abstract;

our $VERSION = (split(/ /, '$Revision: 1.2 $'))[1];

use base qw( Pipeline::Segment );

use constant message => 'declined';

sub dispatch {
    my $self = shift;
    if ($self->should_decline) {
	return new Pipeline::Production()->contents($self->message);
    }
}

sub should_decline {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}


1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Segment::User> class provides a standard way of
declining to continue processing a Pipeline.

This class inherits its interface from C<Pipeline::Segment>.

=head1 METHODS

=over 4

=item $production = $obj->dispatch

Returns a C<Pipeline::Production> with $self->message if $self->should_decline
is true.

=item $boolean = $obj->should_decline

abstract method.

=item $msg = $obj->message

message to decline with.  defaults to 'declined'.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Pipeline::Segment>

=cut
