package Term::YAPI; {
    use strict;
    use warnings;

    our $VERSION = '4.04';

    #####
    #
    # TODO:
    #   types - pulse
    #   STDERR
    #
    #####

    my $threaded_okay;   # Can we do indicators using threads?
    BEGIN {
        eval {
            require threads;
            die if ($threads::VERSION lt '1.31');
            require Thread::Queue;
        };
        $threaded_okay = !$@;
    }

    use Object::InsideOut 4.04;

    # Default progress indicator is a twirling bar
    my @yapi :Field
             :Type(List)
             :Arg('Name' => 'yapi', 'Regex' => qr/^yapi/i);

    # Boolean - indicator is asynchronous?
    my @is_async :Field
                 :Arg('Name' => 'async', 'Regex' => qr/^(?:async|thr)/i);

    # Boolean
    my @erase :Field
              :Arg('Name' => 'erase', 'Regex' => qr/^erase/i, 'Default' => 0);

    # Step counter for indicator
    my @step :Field;

    # Starting value for countdown indicators
    my @countdown :Field
                  :Arg('Name' => 'from', 'Regex' => qr/^from/i);

    # Start time of running indicator
    my @running :Field;

    # Type of indicator = twirl, dots, pulse, ...
    my @type :Field;

    my %init_args :InitArgs = (
        'type' => {
            'Regex'   => qr/^type$/i,
            'Default' => 'anim',
        },
    );


    my $current;   # Currently running indicator
    my $sig_int;   # Remembers existing $SIG{'INT'} handler
    my $queue;     # Shared queue for communicating with indicator thread


    # Terminal control code sequences
    my $HIDE = "\e[?25l";   # Hide cursor
    my $SHOW = "\e[?25h";   # Show cursor
    my $EL   = "\e[K";      # Erase line


    sub import
    {
        my $class = shift;   # Not used

        # Don't use terminal control code sequences for MSDOS console
        if (@_ && $_[0] =~ /(?:ms|win|dos)/i) {
            ($HIDE, $SHOW, $EL) = ('', '', (' 'x40)."\r");
        }
    }


    # Initialize a new indicator object
    sub init :Init
    {
        my ($self, $args) = @_;

        # Indicator type
        if ($$args{'type'} =~ /^anim/i) {
            $type[$$self] = 'anim';
            if (! defined($yapi[$$self])) {
                $yapi[$$self] = [ qw(/ - \ |) ];
            }

        } elsif ($$args{'type'} =~ /^dot/i) {
            $type[$$self] = 'dots';
            if (! defined($yapi[$$self])) {
                $yapi[$$self] = ['.'];
            }

        } elsif ($$args{'type'} =~ /^count$/i) {
            $type[$$self] = 'count';
            $yapi[$$self] = [ 0 ];

        } elsif ($$args{'type'} =~ /^countdown$/i) {
            $type[$$self] = 'countdown';
            if (! defined($countdown[$$self])) {
                OIO::Args->die(
                    'message'  => q/Missing 'From' parameter for countdown timer/,
                    'location' => [ caller(1) ]);
            }
            $yapi[$$self] = [ $countdown[$$self] ];

        } else {
            OIO::Args->die(
                'message'  => "Unknown indicator 'type': '$$args{'type'}'",
                'Usage'    => q/Supported types: 'anim', 'dots', 'count' and 'countdown'/,
                'location' => [ caller(1) ]);
        }

        # If this is the first async indicator, create the indicator thread
        if ($is_async[$$self] && ! $queue && $threaded_okay) {
            my $thr;
            eval {
                # Create communication queue for indicator thread
                if ($queue = Thread::Queue->new()) {
                    # Create indicator thread in 'void' context
                    # Give the thread the queue
                    $thr = threads->create({'void' => 1}, \&_yapi_thread, $queue);
                }
            };
            # If all is well, detach the thread
            if ($thr) {
                $thr->detach();
            } else {
                # Bummer :(  Can't do async indicators.
                undef($queue);
                $threaded_okay = 0;
            }
        }
    }


    # Start the indicator
    sub start :Method(object)
    {
        my $self = shift;
        my $msg  = shift || 'Working: ';

        # Stop currently running indicator
        if ($current) {
            $current->done();
        }

        # Set ourself as running
        $running[$$self] = time();
        $current = $self;
        $step[$$self] = 0;

        # Remember existing interrupt handler
        $sig_int = $SIG{'INT'};

        # Set interrupt handler
        $SIG{'INT'} = sub {
            $self->_done('INTERRUPTED');  # Stop the progress indicator
            kill(shift, $$);              # Propagate the signal
        };

        $| = 1;   # Autoflush

        # Print message and hide cursor
        print("\r$EL$msg$HIDE");

        # Set up progress
        if ($is_async[$$self]) {
            if ($threaded_okay) {
                $queue->enqueue('', $type[$$self], @{$yapi[$$self]});
                threads->yield();
            } else {
                print('wait...');     # Use this when 'async is broken'
            }
        } else {
            print($yapi[$$self][0]);  # First progress step
        }
    }


    # Returns a progress element
    sub _prog :Sub
    {
        my ($type, $yapi, $step, $max) = @_;

        my $prog = ($type eq 'count')     ? $step
                 : ($type eq 'countdown') ? $yapi->[0] - $step
                        : $yapi->[$step % $max];

        return $prog;
    }


    # String length ignoring ANSI color sequences
    sub _length :Sub
    {
        my $s = shift;
        $s =~ s/\e.+?m//g;
        return length($s);
    }

    # Generates a string to erase the previous progress element
    sub _undo :Sub
    {
        my ($type, $yapi, $step, $max, $last) = @_;

        my $undo = ($type eq 'anim')
                        ? ("\b \b" x _length($yapi->[$step % $max]))
                 : ($type eq 'dots')
                        ? (($last) ? ' ' : '')
                 : ($type eq 'count')
                        ? ("\b \b" x _length($step))
                 : ($type eq 'countdown')
                        ? ("\b \b" x _length($yapi->[0] - $step))
                 : '';

        return $undo;
    }


    # Prints out next progress element
    sub progress :Method(object)
    {
        my $self = shift;

        return if ($is_async[$$self]);   # N/A for 'async' indicators

        if ($running[$$self]) {
            my $type = $type[$$self];
            my $yapi = $yapi[$$self];
            my $step = $step[$$self]++;
            my $max  = scalar(@{$yapi});
            print(_undo($type, $yapi, $step,   $max, 0) .
                  _prog($type, $yapi, $step+1, $max))
        } else {
            # Not running, or some other indicator is running.
            # Therefore, start this indicator.
            $self->start();
        }
    }


    # Stop the indicator
    sub _done :Private
    {
        my ($self, $msg) = @_;

        # Ignore if not running
        return if (! $running[$$self]);
        undef($running[$$self]);

        # No longer currently running indicator
        undef($current);

        # Halt indicator thread, if applicable
        if ($is_async[$$self] && $threaded_okay) {
            eval { $queue->enqueue($msg); };
            threads->yield();
            sleep(1);

        } else {
            # Display done message
            print(_undo($type[$$self], $yapi[$$self], $step[$$self], scalar(@{$yapi[$$self]}), 1)
                  . $SHOW . $msg);
        }

        # Restore any previous interrupt handler
        $SIG{'INT'} = $sig_int || 'DEFAULT';
        undef($sig_int);
    }

    # Stop the indicator, and possibly erase the line
    sub done :Method(object)
    {
        my ($self, $msg) = @_;
        $self->_done(($erase[$$self]) ? "\r$EL"  :
                     (defined($msg))  ? "$msg\n" : "done\n");
    }

    # Stop the indicator and report elapsed time
    sub endtime :Method(object)
    {
        my $self = $_[0];
        if (my $start = $running[$$self]) {
            my $time = time() - $start;

            my $hrs = int($time/3600);
            $time -= 3600*$hrs;
            my $min = int($time/60);
            my $sec = $time - 60*$min;

            $self->_done(sprintf("time = %d:%02d:%02d\n", $hrs, $min, $sec));
        }
    }

    # Stop the indicator and erase the line
    sub erase :Method(object)
    {
        $_[0]->_done("\r$EL");
    }


    # Ensure indicator is stopped when indicator object is destroyed
    sub destroy :Destroy
    {
        my $self = shift;
        $self->done();
    }


    # Progress indicator thread entry point function
    sub _yapi_thread :Sub
    {
        my $queue = shift;

        while (1) {
            # Wait for start
            my $item;
            while (! $item) {
                $item = $queue->dequeue();
            }

            # Type of indicator
            my $type = $item;

            # Gather progress elements
            my @yapi;
            while (defined($item = $queue->dequeue_nb())) {
                push(@yapi, $item);
            }

            $| = 1;   # Autoflush

            # Show progress
            my ($step, $max) = (0, scalar(@yapi));
            print($yapi[0]);
            while (! defined($item = $queue->dequeue_nb())) {
                sleep(1);
                print(_undo($type, \@yapi, $step,   $max, 0) .
                      _prog($type, \@yapi, $step+1, $max));
                $step++;
            }

            # Display done message
            print(_undo($type, \@yapi, $step, $max, 1) . $SHOW . $item);
        }
    }
}

1;

__END__

=head1 NAME

Term::YAPI - Yet Another Progress Indicator

=head1 SYNOPSIS

 use Term::YAPI;

 # Synchronous progress indicator: .o0o.o0o.o0o.
 my $yapi = Term::YAPI->new('type' => 'dots', 'yapi' => [ qw(. o 0 o) ]);
 $yapi->start('Working: ');
 foreach (1..10) {
     sleep(1);
     $yapi->progress();
 }
 $yapi->done('done');

 # Asynchronous (threaded) incrementing counter
 my $yapi = Term::YAPI->new('type' => 'count', 'async' => 1);
 $yapi->start('Waiting 10 sec.: ');
 sleep(10);
 $yapi->erase();

=head1 DESCRIPTION

Term::YAPI provides progress indicators on the terminal to let the user know
that something is happening.  The indicator can be in incrementing counter, or
can consist of one or more elements that are displayed cyclically one after
another.

The text cursor is I<hidden> while progress is being displayed, and restored
after the progress indicator finishes.  A C<$SIG{'INT'}> handler is installed
while progress is being displayed so that the text cursor is automatically
restored should the user hit C<ctrl-C>.

The progress indicator can be controlled synchronously by the application, or
can run asynchronously in a thread.

=over

=item my $yapi = Term::YAPI->new()

Creates a new synchronous progress indicator object, using the default
I<twirling bar> indicator:  / - \ |

=item my $yapi = Term::YAPI->new('type' => 'XXX');

The C<'type'> parameter specifies the type of progress indicator to be used:

=over

=item C<'type' =E<gt> 'anim'>

An I<animated> indicator - defaults to the I<twirling bar> indicator.  This is
the default indicator type.

=item C<'type' =E<gt> 'dots'>

A character sequence indicator - defaults to a line of periods/dots:  .....

=item C<'type' =E<gt> 'count'>

An incrementing counter that starts at 0.

=item C<'type' =E<gt> 'countdown'>

An decrementing counter.  The starting value is specified using a (mandatory)
C<'from'> parameter:

 my $yapi = Term::YAPI->new('type' => 'countdown', 'from' => 15);

=back

=item my $yapi = Term::YAPI->new('yapi' => $indicator_array_ref)

The C<'yapi'> parameter supplies an array reference containing the elements
to be used for the indicator.  Examples:

 my $yapi = Term::YAPI->new('yapi' => [ qw(^ > v <) ], 'type' => 'anim');

 my $yapi = Term::YAPI->new('yapi' => [ qw(. o O o) ]);   # Either type

 my $yapi = Term::YAPI->new('yapi' => [ qw(. : | :) ]);   # Either type

This parameter is ignored for C<'type' =E<gt> 'count'> indicators.

=item my $yapi = Term::YAPI->new('async' => 1);

Creates a new asynchronous progress indicator object.

=item my $yapi = Term::YAPI->new('erase' => 1);

Indicates that the entire line occupied by the indicator is to be erased when
the indicator is terminated.

=item $yapi->start($start_msg)

Sets up the interrupt signal handler, hides the text cursor, and prints out
the optional message followed by the first progress element.  The message
defaults to 'Working: '.

For an asynchronous progress indicator, the progress elements display at one
second intervals.

=item $yapi->progress()

Displays the next progress indicator element.

This method is not used with asynchronous progress indicators.

=item $yapi->done($done_msg)

Prints out the optional message (defaults to 'done'), restores the text
cursor, and removes the interrupt handler installed by the C<-E<gt>start()>
method (restoring any previous interrupt handler).

=item $yapi->endtime()

Terminates the indicator as with the C<-E<gt>done()> method, and prints out
the elapsed time for the indicator.

=item $yapi->erase()

Terminates the indicator, and erases the entire line the indicator was on.

=back

The progress indicator object is reusable.  In other words, after using it
once, you can use it again just by using C<$yapi-E<gt>start($start_msg)>.

=head1 EXAMPLE

Term::YAPI will even support using ANSI color sequences in the progress
indicator elements:

 use Term::YAPI;
 use Term::ANSIColor ':constants';

 my $l = BOLD . BLUE . '<' . RESET;
 my $r = BOLD . BLUE . '>' . RESET;
 my $x1 = RED . '.' . RESET;
 my $x2 = RED . 'o' . RESET;
 my $x3 = RED . '0' . RESET;

 my $yapi = Term::YAPI->new('type' => 'anim',
                            'yapi' => [ "$l$x1    $r",
                                        "$l $x2   $r",
                                        "$l  $x3  $r",
                                        "$l   $x2 $r",
                                        "$l    $x1$r",
                                        "$l   $x2 $r",
                                        "$l  $x3  $r",
                                        "$l $x2   $r" ],
                            'async' => 1);

 $yapi->start(GREEN . 'Watch this ' . RESET);
 sleep(10);
 $yapi->done(YELLOW . '- cool, eh?' . RESET);

=head1 INSTALLATION

The following will install YAPI.pm under the F<Term> directory in your Perl
installation:

 cp YAPI.pm `perl -MConfig -e'print $Config{privlibexp}'`/Term/

or as part of the Object::InsideOut installation process:

 perl Makefile.PL
 make
 make yapi
 make install

=head1 LIMITATIONS

Works, as is, on C<xterm>, C<rxvt>, and the like.  When used with MSDOS
consoles, you need to add the C<:MSDOS> flag to the module declaration line:

 use Term::YAPI ':MSDOS';

When used as such, the text cursor will not be hidden when progress is being
displayed.

Generating multiple progress indicator objects and running them at different
times in an application is supported.  This module will not allow more than
one indicator to run at the same time.

Trying to use asynchronous progress indicators on non-threaded Perls will
not cause an error, but will only display 'wait...'.

=head1 SEE ALSO

L<Object::InsideOut>, L<threads>, L<Thread::Queue>

=head1 AUTHOR

Jerry D. Hedden, S<E<lt>jdhedden AT cpan DOT orgE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 - 2012 Jerry D. Hedden. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
