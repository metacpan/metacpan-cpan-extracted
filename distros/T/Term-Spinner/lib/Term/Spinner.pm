package Term::Spinner;

use strict;
use warnings;
use 5.006_000;
our $VERSION = '0.01';

=head1 NAME

Term::Spinner - A progress spinner for commandline programs

=head1 SYNOPSIS

  use Term::Spinner;

  my $spinner = Term::Spinner->new();
  while(... doing something ...) {
      $spinner->advance();
      # Do things...
  }
  undef $spinner; # clears final spinner output by default.

=head1 DESCRIPTION

This module provides a simple one-character spinner for commandline
programs.  You can use this to keep the user from getting bored
while your program performs a long operation.

You can override the array of graphical characters used to draw
the spinner (by default, C<-, \, |, /,> and C<x> for "finished").

It clears the spinner for re-drawing by using a sequence
of backspace, space, backspace.  I've found this works for me
on all of the terminals I use, without having to get into all
the C<$TERM> types and various special escape sequences.

In the future, I may add support for using escape sequences for
well-known terminal types, if it can be done reliably.

Try C<perl examples/various.pl> in this distribution to see
some sample spinners in action.

=cut

use Carp qw/croak/;
use IO::Handle;

use Moose;

=head1 ATTRIBUTES

These can be used as options to C<new>, or modified at any
time by calling them as accessors on an object.

=head2 spin_chars

An arrayref of characters used to draw the spinner.  The default
is C<-, \, |, /, x>.  The final character of this array is not
used during the normal spin cycle, it is used when you call
L</finish>, to indicate the spinner is done spinning.

=cut

has 'spin_chars' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { ['-', '\\', '|', '/', 'x'] },
);

has '_spinner' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has '_drawn' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

=head2 output_handle

The filehandle to use when drawing the spinner.  Defaults to
C<STDERR>.

=cut

has 'output_handle' => (
    is => 'rw',
    isa => 'FileHandle',
    default => sub { \*STDERR },
    trigger => sub { $_[1]->autoflush(1) },
);

=head2 clear_on_destruct

Boolean setting for whether the spinner should L</clear> itself
when the object is destructed.  Defaults to true.

=cut

has 'clear_on_destruct' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

=head2 finish_on_destruct

Boolean setting for whether the spinner should L</finish> itself
when the object is destructed.  Defaults to true.  Has little
noticeable effect if L</clear_on_destruct> is also enabled, as
the finish character will be cleared immediately.

=cut

has 'finish_on_destruct' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

=head1 METHODS

=head2 new

Provided by Moose.  Accepts the attributes above as a simple
hash.  Example:

  my $sp = Term::Spinner->new(
    clear_on_destruct => 0,
    output_handle => \*STDOUT,
  );

=head2 clear

Clears the spinner's output, if any.

  $sp->clear();

=cut

sub clear {
    my ($self) = @_;

    $self->output_handle->print("\010 \010") if $self->_drawn;
    $self->_drawn(0);
}

=head2 draw

Draws the spinner in its current state, clearing first.
This is done automatically on L</advance> and L</finish>

  $sp->draw();

=cut

sub draw {
    my ($self) = @_;

    $self->clear();
    $self->output_handle->print($self->spin_chars->[$self->_spinner]);
    $self->_drawn(1);
}

=head2 advance

Advance the spinner by one character and redraw.

  $sp->advance();

=cut

sub advance {
    my ($self) = @_;

    $self->_spinner(($self->_spinner + 1) % $#{$self->spin_chars});
    $self->draw();
}

=head2 finish

Set the spinner to the finish character and redraw

  $sp->finish();

=cut

sub finish {
    my ($self) = @_;

    $self->_spinner($#{$self->spin_chars});
    $self->draw();
}

sub _destruct_cleanup {
    my ($self) = @_;

    $self->finish if $self->finish_on_destruct;
    $self->clear if $self->clear_on_destruct;
}

=head2 DEMOLISH

Our Moose destructor, handles finish/clear on destruct,
if not disabled.

=cut

=head2 meta

Moose meta info.

=cut

sub DEMOLISH { shift->_destruct_cleanup }

no Moose;

=head1 AUTHOR

Brandon L. Black, E<lt>blblack@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Brandon L. Black

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
