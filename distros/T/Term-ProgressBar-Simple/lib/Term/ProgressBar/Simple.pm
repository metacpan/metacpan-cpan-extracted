package Term::ProgressBar::Simple;

use strict;
use warnings;

use Term::ProgressBar::Quiet;

use overload    #
  '++' => \&increment,    #
  '+=' => \&increment;    #
                          # '--' => \&decrement; # add later

our $VERSION = '0.03';

=head1 NAME

Term::ProgressBar::Simple - simpler progress bars

=head1 SYNOPSIS

    # create some things to loop over
    my @things = (...);
    my $number_of_things = scalar @things;

    # create the progress bar object
    my $progress = Term::ProgressBar::Simple->new( $number_of_things );

    # loop
    foreach my $thing (@things) {

        # do some work
        $thing->do_something();

        # increment the progress bar object to tell it a step has been taken.
        $progress++;
    }

    # See also use of '$progress += $number' later in pod

=head1 DESCRIPTION

Progress bars are handy - they tell you how much work has been done, how much is
left to do and estimate how long it will take.

But they can be fiddly!

This module does the right thing in almost all cases in a really convenient way.

=head1 FEATURES

Lots - does all the best practice:

Wraps L<Term::ProgressBar::Quiet> so there is no output unless the code is
running interactively - lets you put them in cron scripts.

Deals with minor updates - only refreshes the screen when it will change what
the user sees so it is efficient.

Completes the progress bar when the progress object is destroyed (explicitly or
by going out of scope) - no more '99%' done.


=head1 METHODS

=head2 new

    # Either...
    my $progress = Term::ProgressBar::Simple->new($count);

    # ... or
    my $progress = Term::ProgressBar::Simple->new(
        {
            count => $count,               #
            name  => 'descriptive text',
        }
    );

Create a new progress bar. Either just pass in the number of things to do, or a
config hash. See L<Term::ProgressBar> for details.

=cut

sub new {
    my $class = shift;
    my $input = shift;

    # if we didn't get a hashref assume we got a count
    $input = { count => $input } unless ref $input;

    # create the T::PB::Q args with defaults.
    my $args = {
        ETA  => 'linear',      # only sensible choice
        name => 'progress',    # seems reasonable
        %$input,
    };

    my $tpq = Term::ProgressBar::Quiet->new($args);

    my $self = {
        args         => $args,
        tpq          => $tpq,
        count_so_far => 0,
        next_update  => 0,
    };

    return bless $self, $class;
}

=head2 increment ( ++ )

    $progress++;

Incrementing the object causes the progress display to be updated. It is smart
about checking to see if the display needs to be updated.

=head2 increment ( += )

    $progress += $number_done;

Sometimes you'll have done more than one step between updates. A good example is
processing logfiles, where the time taken is relative to the size of the file.
In this case code like this would give a better feel for the progress made:

    # Get the total size of all the files
    my $total_size = sum map { -s } @filenames;

    # Set up object with total size as steps to do
    my $progress = Term::ProgressBar::Simple->new($total_size);

    # process each file and increment by the size of each file
    foreach my $filename (@filenames) {
        process_the_file($filename);
        $progress += -s $filename;
    }

=cut

sub increment {
    my $self = shift;
    my $increment = shift || 1;

    $self->{count_so_far} += $increment;
    my $now = $self->{count_so_far};

    if ( $now >= $self->{next_update} ) {
        $self->{next_update} = $self->{tpq}->update($now);
    }

    return $self;
}

=head2 message

    $progress->message('Copying $filename');

Output a message. This is very much like print, but we try not to
disturb the terminal.

=cut

sub message {
    my($self, $message) = @_;
    $self->{tpq}->message($message);
}

# want to add this in a later version.
#
# while ( $progress-- ) {
#     # do something
# }
#
# =head2 decrement
#
#
# =cut
#
# sub _decrement {
#     my $self = shift;
#
#     # increment and get the number done
#     my $number_done = $self->increment;
#
#     # return number remaining, or zero if overshot
#     my $remaining = $self->{args}{count} - $number_done;
#     $remaining = 0 if $remaining < 0;
#
#     return $self;
# }

sub DESTROY {
    my $self = shift;

    $self->{tpq}->update( $self->{args}{count} ) if $self->{tpq};

    return;
}

=head1 SEE ALSO

L<Term::ProgressBar> & L<Term::ProgressBar::Quiet>

=head1 GOTCHAS

Not all operators are overloaded, so things might blow up in interesting ways.
Patches welcome.

=head1 THANKS

Martyn J. Pearce for the orginal and great L<Term::ProgressBar>.

Leon Brocard for doing the hard work in L<Term::ProgressBar::Quiet>, and for
submitting a patch with the code for C<+=>..

YAPC::EU::2008 for providing the venue and coffee whilst the first version of
this module was written.

=head1 AUTHOR

Edmund von der Burg C<< <evdb@ecclestoad.co.uk> >>. 

L<http://www.ecclestoad.co.uk/>

=head1 BUGS

There are no tests - there should be. The smart way would be to trap the output
and check it is right.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Edmund von der Burg C<< <evdb@ecclestoad.co.uk> >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
