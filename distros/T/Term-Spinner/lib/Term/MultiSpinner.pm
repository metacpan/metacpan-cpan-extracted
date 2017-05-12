package Term::MultiSpinner;

use strict;
use warnings;
use 5.006_000;
our $VERSION = '0.01';

=head1 NAME

Term::MultiSpinner - Term::Spinner with multiple spinners

=head1 SYNOPSIS

  use Term::MultiSpinner;

  my $spinner = Term::MultiSpinner->new();
  while(... a complicated async loop ...) {
      if(... can read some data ...) {
          $spinner->advance(0);
          # read stuff
          $spinner->finish(0) if $done_reading;
      }
      if(... can write some data ...) {
          $spinner->advance(1);
          # write stuff
          $spinner->finish(1) if $done_writing;
      }
  }
  undef $spinner; # clears final spinner output by default.

=head1 DESCRIPTION

This is a subclass of L<Term::Spinner>, see those docs first.

This class provides multiple spinners on the same line, to
represent the state of several asynchronous long-running
tasks.  Ideal for a complex C<select>-based loop, a L<POE>
process, etc.

Another good place to use it is if you have a long queue of
short tasks to complete and can only do a small number in
parallel at a time.  Use the first spinner to indicate when
a task is taken from the queue and started, and the second
spinner to indicate task completion.

The docs below only indicate deviations from the interface
of L<Term::Spinner>, see those docs for the basic information.

=cut

use Carp qw/croak/;
use IO::Handle;

use Moose;
extends 'Term::Spinner';

has '_spinners' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

has '_suppress_draw' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

=head1 METHODS

=head2 clear

=cut

sub clear {
    my ($self) = @_;

    my $drawn = $self->_drawn;
    return if !$drawn;

    $self->output_handle->print(
        "\010" x $drawn,
        q{ } x $drawn,
        "\010" x $drawn,
    );
    $self->_drawn(0);
}

=head2 draw

=cut

sub draw {
    my ($self) = @_;

    return if $self->_suppress_draw;

    $self->clear();
    $self->output_handle->print(
        join(q{}, map { $self->spin_chars->[$_] } @{$self->_spinners})
    );
    $self->_drawn(scalar(@{$self->_spinners}));
}

=head2 advance

Requires an argument, which is the integer spinner slot to advance.
The first spinner is C<0>.  The number of spinners on the screen
will always automagically expand to include the entire range of
C<0> through the highest number you've directly accessed.

=cut

sub advance {
    my ($self, $which) = @_;

    croak "advance() requires a spinner number"
        if !defined $which;

    my $spinners = $self->_spinners;

    if($which > $#$spinners) {
        push(@$spinners, 0) for (1..($which-$#$spinners));
    }
    $spinners->[$which] = ($spinners->[$which] + 1) % $#{$self->spin_chars};
    $self->draw();
}

=head2 finish

Requires an argument, which is the integer spinner slot to finish.
The first spinner is C<0>.  The number of spinners on the screen
will always automagically expand to include the entire range of
C<0> through the highest number you've directly accessed.

=cut

sub finish {
    my ($self, $which) = @_;

    croak "finish() requires a spinner number"
        if !defined $which;

    $self->_spinners->[$which] = $#{$self->spin_chars};
    $self->draw();
}

=head2 advance_all

Calls L</advance> on all spinners.

=cut

sub advance_all {
    my ($self) = @_;

    $self->_suppress_draw(1);
    $self->advance($_) for (0..$#{$self->_spinners});
    $self->_suppress_draw(0);
    $self->draw();
}

=head2 finish_all

Calls L</finish> on all spinners.

=cut

sub finish_all {
    my ($self) = @_;

    $self->_suppress_draw(1);
    $self->finish($_) for (0..$#{$self->_spinners});
    $self->_suppress_draw(0);
    $self->draw();
}

sub _destruct_cleanup {
    my ($self) = @_;

    $self->finish_all if $self->finish_on_destruct;
    $self->clear if $self->clear_on_destruct;
}

no Moose;

=head1 AUTHOR

Brandon L. Black, E<lt>blblack@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Brandon L. Black

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
