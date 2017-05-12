#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Logging and debugging message handler for Piper
#####################################################################

package Piper::Logger;

use v5.10;
use strict;
use warnings;

use Carp qw();
# use Data::Dump qw(dump); # required if needed

use Moo;

with qw(Piper::Role::Logger);

our $VERSION = '0.04'; # from Piper-0.04.tar.gz

#pod =head1 CONSTRUCTOR
#pod
#pod =head2 new
#pod
#pod =head1 METHODS
#pod
#pod =head2 DEBUG($segment, $message, @items)
#pod
#pod This method is a no-op unless S<<< C<< $self->debug_level($segment) > 0 >> >>>.
#pod
#pod Prints an informational message to STDERR.
#pod
#pod Uses the method C<make_message> to format the printed message according to the debug/verbose levels of C<$segment>.
#pod
#pod Labels the message by pre-pending 'Info: ' to the formatted message.
#pod
#pod =cut

sub DEBUG {
    my $self = shift;
    $self->INFO(@_);
}

#pod =head2 ERROR($segment, $message, @items)
#pod
#pod Prints an error to STDERR and dies via L<Carp::croak|Carp>.
#pod
#pod Uses the method C<make_message> to format the printed message according to the debug/verbose levels of C<$segment>.
#pod
#pod Labels the message by pre-pending 'Error: ' to the formatted message.
#pod
#pod =cut

sub ERROR {
    my $self = shift;
    Carp::croak('Error: '.$self->make_message(@_));
}

#pod =head2 INFO($segment, $message, @items)
#pod
#pod This method is a no-op unless S<<< C<< $self->verbose_level($segment) > 0 >> >>> or S<<< C<< $self->debug_level($segment) > 0 >> >>>.
#pod
#pod Prints an informational message to STDERR.
#pod
#pod Uses the method C<make_message> to format the printed message according to the debug/verbose levels of C<$segment>.
#pod
#pod Labels the message by pre-pending 'Info: ' to the formatted message.
#pod
#pod =cut

sub INFO {
    my $self = shift;
    say STDERR 'Info: '.$self->make_message(@_);
}

#pod =head2 WARN($segment, $message, @items)
#pod
#pod Prints a warning to STDERR via L<Carp::carp|Carp>.
#pod
#pod Uses the method C<make_message> to format the printed message according to the debug/verbose levels of C<$segment>.
#pod
#pod Labels the message by pre-pending 'Warning: ' to the formatted message.
#pod
#pod =cut

sub WARN {
    my $self = shift;
    Carp::carp('Warning: '.$self->make_message(@_));
}

#pod =head1 UTILITY METHODS
#pod
#pod =head2 make_message($segment, $message, @items)
#pod
#pod Formats and returns the message according to the debug/verbose levels of C<$segment> and the provided arguments.
#pod
#pod There are two-three parts to the message:
#pod
#pod     segment_name: message <items>
#pod
#pod The message part is simply C<$message> for all debug/verbose levels.
#pod
#pod The <items> part is only included when the verbosity level of the segment is greater than 1.  It is formatted by L<Data::Dump>.
#pod
#pod If the verbosity and debug levels are both 0, segment_name is simply the segment's C<label>.  If the verbosity level of the segment is greater than zero, the full path of the segment is used instead of C<label>.  If the debug level of the segment is greater than 1, the segment's C<id> is appended to C<label>/C<path> in parentheses.
#pod
#pod =cut

sub make_message {
    my ($self, $segment, $message, @items) = @_;

    $message = ($self->verbose_level($segment) ? $segment->path : $segment->label)
        . ($self->debug_level($segment) > 1 ? ' (' . $segment->id . '): ' : ': ')
        . $message;

    if ($self->verbose_level($segment) > 1 and @items) {
        require Data::Dump;

        $message .= ' ' . Data::Dump::dump(@items);
    }

    return $message;
}

#pod =head2 debug_level($segment)
#pod
#pod =head2 verbose_level($segment)
#pod
#pod These methods determine the appropriate debug and verbosity levels for the given $segment, while respecting any environment variable overrides.
#pod
#pod Available environment variable overrides:
#pod
#pod     PIPER_DEBUG
#pod     PIPER_VERBOSE
#pod
#pod =cut

1;

__END__

=pod

=for :stopwords Mary Ehlers Heaney Tim

=head1 NAME

Piper::Logger - Logging and debugging message handler for Piper

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 DEBUG($segment, $message, @items)

This method is a no-op unless S<<< C<< $self->debug_level($segment) > 0 >> >>>.

Prints an informational message to STDERR.

Uses the method C<make_message> to format the printed message according to the debug/verbose levels of C<$segment>.

Labels the message by pre-pending 'Info: ' to the formatted message.

=head2 ERROR($segment, $message, @items)

Prints an error to STDERR and dies via L<Carp::croak|Carp>.

Uses the method C<make_message> to format the printed message according to the debug/verbose levels of C<$segment>.

Labels the message by pre-pending 'Error: ' to the formatted message.

=head2 INFO($segment, $message, @items)

This method is a no-op unless S<<< C<< $self->verbose_level($segment) > 0 >> >>> or S<<< C<< $self->debug_level($segment) > 0 >> >>>.

Prints an informational message to STDERR.

Uses the method C<make_message> to format the printed message according to the debug/verbose levels of C<$segment>.

Labels the message by pre-pending 'Info: ' to the formatted message.

=head2 WARN($segment, $message, @items)

Prints a warning to STDERR via L<Carp::carp|Carp>.

Uses the method C<make_message> to format the printed message according to the debug/verbose levels of C<$segment>.

Labels the message by pre-pending 'Warning: ' to the formatted message.

=head1 UTILITY METHODS

=head2 make_message($segment, $message, @items)

Formats and returns the message according to the debug/verbose levels of C<$segment> and the provided arguments.

There are two-three parts to the message:

    segment_name: message <items>

The message part is simply C<$message> for all debug/verbose levels.

The <items> part is only included when the verbosity level of the segment is greater than 1.  It is formatted by L<Data::Dump>.

If the verbosity and debug levels are both 0, segment_name is simply the segment's C<label>.  If the verbosity level of the segment is greater than zero, the full path of the segment is used instead of C<label>.  If the debug level of the segment is greater than 1, the segment's C<id> is appended to C<label>/C<path> in parentheses.

=head2 debug_level($segment)

=head2 verbose_level($segment)

These methods determine the appropriate debug and verbosity levels for the given $segment, while respecting any environment variable overrides.

Available environment variable overrides:

    PIPER_DEBUG
    PIPER_VERBOSE

=head1 SEE ALSO

=over

=item L<Piper::Role::Logger>

=item L<Piper>

=back

=head1 VERSION

version 0.04

=head1 AUTHOR

Mary Ehlers <ehlers@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mary Ehlers.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
