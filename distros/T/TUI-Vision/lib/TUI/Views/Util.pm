package TUI::Views::Util;
# ABSTRACT: defines various utility functions for views

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  message
);

use TUI::toolkit qw( signature );
use TUI::toolkit::Types qw(
  Maybe
  :types
);

use TUI::Drivers::Const qw( evNothing );
use TUI::Drivers::Event;

sub message {    # $view|undef ($receiver|undef, $what, $command, $infoPtr)
  state $sig = signature(
    pos => [
      Maybe[Object],
      PositiveOrZeroInt, 
      PositiveOrZeroInt,
      Any,
    ],
  );
  my ( $receiver, $what, $command, $infoPtr ) = $sig->( @_ );

  return undef
    unless $receiver;

  my $event = TEvent->new(
    what    => $what,
    message => {
      command => $command,
      infoPtr => $infoPtr,
    },
  );

  $receiver->handleEvent( $event );

  if ( $event->{what} == evNothing ) {
    return $event->{message}{infoPtr};
  }
  else {
    return undef;
  }
} #/ sub message

1

__END__

=pod

=head1 NAME

TUI::Views::Util - utility functions for views

=head1 SYNOPSIS

  use TUI::Views::Util qw(message);

  my $handled_by = message(
    $receiver,
    evMessage,
    cmScrollBarChanged,
    $sender
  );

=head1 DESCRIPTION

C<TUI::Views::Util> provides low-level utility functions used throughout the
TUI::Vision view system.

The functions in this module operate on views and events and are intended to
simplify common interaction patterns such as message dispatching and command
broadcasting between views.

This module is purely functional and does not define any classes or objects.

=head1 FUNCTIONS

=head2 message

  my $view | undef = message($receiver | undef, $what, $command, $infoPtr);

Sends a message event to a view and returns the view that ultimately handled
the message, or C<undef> if the message was not handled.

The function constructs a message event using the supplied C<what>,
C<command>, and C<infoPtr> parameters and invokes the event handling mechanism
starting at the specified receiver.

=over

=item receiver

The target view that receives the message. If C<undef>, the message is sent to
the current view context. (TView | undef)

=item what

The event type being sent. This is typically C<evMessage> or
C<evBroadcast>. (Int)

=item command

The command identifier associated with the message. This usually corresponds
to a C<cmXXXX> constant. (Int)

=item infoPtr

Optional reference to additional contextual information associated with the
message.

This value may be used to pass a data structure, an object, or a reference to
the sending view, depending on the semantics of the command.
(Ref | undef)

=back

=head1 USAGE NOTES

The C<message> function is a convenience wrapper around the TUI::Vision event
dispatch mechanism.

Messages are delivered by invoking the C<handleEvent> method of the receiver.
If the receiver does not handle the message, it may be propagated to child
views depending on the event type and view hierarchy.

The return value indicates which view actually processed the message. This
allows callers to detect whether a command was handled and by whom.

This function is intended for use within a running TUI::Vision application.
Calling it outside of a valid view context will have no useful effect.

=head1 SEE ALSO

L<TUI::Drivers::Event>,
L<TUI::Views::View>,
L<TUI::Views::Group>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
