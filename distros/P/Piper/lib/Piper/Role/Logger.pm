#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Role for logging and debugging in the Piper system
#####################################################################

package Piper::Role::Logger;

use v5.10;
use strict;
use warnings;

use Carp;
use Types::Common::Numeric qw(PositiveOrZeroNum);

use Moo::Role;

our $VERSION = '0.05'; # from Piper-0.05.tar.gz

#TODO: Look into making this Log::Any-compatible

#pod =head1 DESCRIPTION
#pod
#pod The role exists to support future subclassing and testing of the logging mechanism used by L<Piper>.
#pod
#pod =head1 REQUIRES
#pod
#pod This role requires the definition of the below methods, each of which will be provided the following arguments:
#pod
#pod   $segment  # The pipeline segment calling the method
#pod   $message  # The message sent (a string)
#pod   @items    # Items that provide context to the message
#pod
#pod =head2 DEBUG
#pod
#pod This method is only called if the debug level of the segment is greater than zero.
#pod
#pod =cut

requires 'DEBUG';

around DEBUG => sub {
    my ($orig, $self, $instance) = splice @_, 0, 3;
    return unless $self->debug_level($instance);
    $self->$orig($instance, @_);
};

#pod =head2 ERROR
#pod
#pod This method should cause a C<die> or C<croak>.  It will do so automatically if not done explicitly, though with an extremely generic and unhelpful message.
#pod
#pod =cut

requires 'ERROR';

after ERROR => sub {
    croak 'ERROR encountered';
};

#pod =head2 INFO
#pod
#pod This method is only called if either the verbosity or debug levels of the segment are greater than zero.
#pod
#pod =cut

requires 'INFO';

around INFO => sub {
    my ($orig, $self, $instance) = splice @_, 0, 3;
    return unless $self->debug_level($instance) or $self->verbose_level($instance);
    $self->$orig($instance, @_);
};

#pod =head2 WARN
#pod
#pod This method should issue a warning (such as C<warn> or C<carp>).
#pod
#pod =cut

requires 'WARN';

#pod =head1 UTILITY METHODS
#pod
#pod =head2 debug_level($segment)
#pod
#pod =head2 verbose_level($segment)
#pod
#pod These methods should be used to determine the appropriate debug and verbosity levels for the logger.  They honor the following environment variable overrides (if they exist) before falling back to the appropriate levels set by the given C<$segment>:
#pod
#pod     PIPER_DEBUG
#pod     PIPER_VERBOSE
#pod
#pod =cut

sub debug_level {
    return $ENV{PIPER_DEBUG} // $_[1]->debug;
}

sub verbose_level {
    return $ENV{PIPER_VERBOSE} // $_[1]->verbose;
}

1;

__END__

=pod

=for :stopwords Mary Ehlers Heaney Tim

=head1 NAME

Piper::Role::Logger - Role for logging and debugging in the Piper system

=head1 DESCRIPTION

The role exists to support future subclassing and testing of the logging mechanism used by L<Piper>.

=head1 REQUIRES

This role requires the definition of the below methods, each of which will be provided the following arguments:

  $segment  # The pipeline segment calling the method
  $message  # The message sent (a string)
  @items    # Items that provide context to the message

=head2 DEBUG

This method is only called if the debug level of the segment is greater than zero.

=head2 ERROR

This method should cause a C<die> or C<croak>.  It will do so automatically if not done explicitly, though with an extremely generic and unhelpful message.

=head2 INFO

This method is only called if either the verbosity or debug levels of the segment are greater than zero.

=head2 WARN

This method should issue a warning (such as C<warn> or C<carp>).

=head1 UTILITY METHODS

=head2 debug_level($segment)

=head2 verbose_level($segment)

These methods should be used to determine the appropriate debug and verbosity levels for the logger.  They honor the following environment variable overrides (if they exist) before falling back to the appropriate levels set by the given C<$segment>:

    PIPER_DEBUG
    PIPER_VERBOSE

=head1 SEE ALSO

=over

=item L<Piper::Logger>

=item L<Piper>

=back

=head1 VERSION

version 0.05

=head1 AUTHOR

Mary Ehlers <ehlers@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mary Ehlers.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
