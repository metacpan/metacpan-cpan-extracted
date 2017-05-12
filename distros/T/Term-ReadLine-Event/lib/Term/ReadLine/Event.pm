package Term::ReadLine::Event;
$Term::ReadLine::Event::VERSION = '0.05';
use 5.006;
use strict;
use warnings;

use Term::ReadLine 1.09;
use Scalar::Util qw(blessed);

# ABSTRACT: Wrappers for Term::ReadLine's new event_loop model.


sub _new {
    my $class = shift;
    my $app   = shift;

    my $self = bless {@_}, $class;

    $self->{_term} = blessed $app ? $app :
       Term::ReadLine->new(ref $app ? @$app : $app);
    $self;
}


sub with_AnyEvent {
    my $self = _new(@_);

    $self->trl->event_loop(
                           sub {
                               my $data = shift;
                               $data->[0] = AE::cv();
                               $data->[0]->recv();
                           }, sub {
                               my $fh = shift;

                               # The data for AE are: the file event watcher (which
                               # cannot be garbage collected until we're done) and
                               # a placeholder for the condvar we're sharing between
                               # the AE::io callback created here and the wait
                               # callback above.
                               my $data = [];
                               $data->[1] = AE::io($fh, 0, sub { $data->[0]->send() });
                               $data;
                           }
                          );

    $self;
}


sub with_Coro {
    my $self = _new(@_);
    require Coro::Handle;

    $self->trl->event_loop(
                           sub {
                               # Tell Coro to wait until we have something to read,
                               # and then we can return.
                               shift->readable();
                           }, sub {
                               # in Coro, we just need to unblock the filehandle,
                               # and save the unblocked filehandle.
                               my $fh = shift;
                               Coro::Handle::unblock $fh;
                           }
                          );
    $self;
}


sub with_IO_Async {
    my $self = _new(@_);

    $self->trl->event_loop(
                           sub {
                               my $ready = shift;
                               $$ready = 0;
                               $self->{loop}->loop_once while !$$ready;
                           },
                           sub {
                               my $fh = shift;

                               # The data for IO::Async is just the ready flag.  To
                               # ensure we're referring to the same value, this is
                               # a SCALAR ref.
                               my $ready = \ do{my $dummy};

                               # Term::ReadLine::Gnu::XS relies on the fh being
                               # able to do fileno.
                               unless($fh->can('fileno')) {
                                   require IO::Handle;
                                   my $h = IO::Handle->new;
                                   $h->fdopen($fh, 'r') or die "could not fdopen - $!";
                                   $fh = $h
                               }

                               $self->{loop}->add(
                                                  $self->{watcher} =
                                                  IO::Async::Handle->new(
                                                                         read_handle => $fh,
                                                                         on_read_ready => sub { $$ready = 1 },
                                                                        )
                                                 );
                               $ready;
                           }
                          );

    $self->{_cleanup} = sub {
        my $s = shift;
        $s->{loop}->remove($s->{watcher});
    };

    $self;
}


sub with_POE
{
    my $self = _new(@_);

    my $waiting_for_input;

    POE::Session->create(
    inline_states => {

      # Initialize the session that will drive Term::ReadLine.
      # Tell Term::ReadLine to invoke a couple POE event handlers when
      # it's ready to wait for input, and when it needs to register an
      # I/O watcher.

      _start => sub {
        $self->trl->event_loop(
          $_[POE::Session->SESSION]->callback('term_readline_waitfunc'),
          $_[POE::Session->SESSION]->callback('term_readline_regfunc'),
        );
      },

      # This callback is invoked every time Term::ReadLine wants to
      # read something from its input file handle.  It blocks
      # Term::ReadLine until input is seen.
      #
      # It sets a flag indicating that input hasn't arrived yet.
      # It watches Term::ReadLine's input filehandle for input.
      # It runs while it's waiting for input.
      # It turns off the input watcher when it's no longer needed.
      #
      # POE::Kernel's run_while() dispatches other events (including
      # "term_readline_readable" below) until $waiting_for_input goes
      # to zero.

      term_readline_waitfunc => sub {
        my $input_handle = $_[POE::Session->ARG1][0];
        $waiting_for_input = 1;
        $_[POE::Session->KERNEL]->select_read($input_handle => 'term_readline_readable');
        $_[POE::Session->KERNEL]->run_while(\$waiting_for_input);
        $_[POE::Session->KERNEL]->select_read($input_handle => undef);
      },

      # This callback is invoked as Term::ReadLine is starting up for
      # the first time.  It saves the exposed input filehandle where
      # the "term_readline_waitfunc" callback can see it.

      term_readline_regfunc => sub {
        my $input_handle = $_[POE::Session->ARG1][0];
        return $input_handle;
      },

      # This callback is invoked when data is seen on Term::ReadLine's
      # input filehandle.  It clears the $waiting_for_input flag.
      # This causes run_while() to return in "term_readline_waitfunc".

      term_readline_readable => sub {
        $waiting_for_input = 0;
      },
    },
  );
    $self;
}


sub with_Reflex
{
    my $self = _new(@_);

    $self->trl->event_loop(
                           sub {
                               my $input_watcher = shift();
                               $input_watcher->next();
                           },
                           sub {
                               my $input_handle  = shift();
                               my $input_watcher = Reflex::Filehandle->new(
                                                                           handle => $input_handle,
                                                                           rd     => 1,
                                                                          );
                               return $input_watcher;
                           },
                          );


    $self;
}


sub with_Tk
{
    my $self = _new(@_);

    $self->trl->event_loop(
                           sub {
                               my $data = shift;
                               Tk::DoOneEvent(0) until $$data;
                               $$data = 0;
                           },
                           sub {
                               # save filehandle for unhooking later.
                               $self->{tkFH} = shift;
                               my $data;
                               $$data = 0;
                               Tk->fileevent($self->{tkFH}, 'readable', sub { $$data = 1 });
                               $data;
                           },
                          );

    $self->{_cleanup} = sub {
        my $s = shift;
        Tk->fileevent($s->{tkFH}, 'readable', "");
    };

    $self;
}


sub DESTROY
{
    my $self = shift;

    local $@;
    eval {
        $self->trl->event_loop(undef);

        $self->{_cleanup}->($self) if $self->{_cleanup};
    };
}


sub trl
{
    my $self = shift;
    $self->{_term};
}

our $AUTOLOAD;
sub AUTOLOAD
{
    (my $f = $AUTOLOAD) =~ s/.*:://;

    no strict 'refs';
    *{$f} = sub {
        shift->trl()->$f(@_);
    };

    goto &$f;
}


1; # End of Term::ReadLine::Event

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::ReadLine::Event - Wrappers for Term::ReadLine's new event_loop model.

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use AnyEvent;
    use Term::ReadLine::Event;

    my $term = Term::ReadLine::Event->with_AnyEvent('...');

    my $input = $term->readline('Prompt >');

=head1 DESCRIPTION

Provides many of the event loop interactions shown in the examples
provided as a small change to your code rather than the longer code
required.

This may actually be sufficient for your use, or it may not.  This likely
depends on the loop being used.

=head1 HISTORY

This project started with a goal: to get L<Term::ReadLine> working under
L<Coro>.  Since L<Coro> used L<AnyEvent>, I thought that getting
L<Term::ReadLine> to use AnyEvent instead of Tk directly would be a win.
Conversations ensued, and it sounded like P5P generally liked the idea, but
didn't want anything AnyEvent-specific when it could be more generic than
that.

Through a couple of iterations, the event_loop interface was born.  However,
since this was no longer as simple as the old Tk interface (C<$term-E<gt>tkRunning(1)>),
I thought it would need some examples.  Putting examples into the perl core
seemed a bit strange, partly due to the extra overhead involved in updating
them, so having a distribution on CPAN full of examples seemed to make sense.
When looking for information on a module, my first place to look is CPAN,
so that made sense to me.

I then got some examples from other event loop developers (Paul "LeoNerd"
Evans and Rocco Caputo), and added them to my AnyEvent and Coro examples,
and that was the first release.  If others submit further examples, I will
add them and maybe this will grow.  Even if it doesn't, as long as it helps
people integrate Term::ReadLine into their event-loop-based apps, whether that's
Reflex or POE or AnyEvent or Coro or even using select loops to just do some
background processing, then it will have met its goal.

Having compiled a list of examples, I then realised that most of the examples
could be abstracted into a module.  Again, directly into Term::ReadLine
would be too specific for P5P, but just perfect for a distribution.  If you
choose to install this distribution instead of just swiping the example that
suits you, you can integrate with an event loop in a single line (for L<POE>,
that's significant savings, for L<Coro>, not so much).

Note that the examples are more complete than the test files as well. This is
largely because testing full readline functionality in an automated fashion is
not entirely trivial.  The hope would be that anyone making changes to
Term::ReadLine in the future be able to use these examples in their own
testing to ensure they don't break anything.  (If you do, be sure you're
testing with L<Term::ReadLine::Gnu> and L<Term::ReadLine::Perl>, testing
with just L<Term::ReadLine::Stub> will miss things.)

Hopefully, this makes it trivial enough to use event loops with T::RL
such that anyone can do it.  You can get back to focusing on your
business logic instead of arcane rituals to get event loops integrated
with Term::ReadLine.  And hopefully that means we get more perl apps
that have nice interfaces (with readline support), even when doing
other things in the background (events).

It is not my intention to provide wrappers for all event loops.  It is
my intention only to provide examples for as many loops as possible. 
The wrappers are intended to be examples as well (though covered under
Artistic/GPL licensing whereas the examples themselves are more
permissive), and not necessarily used as-is, partially due to their
size (all the wrappers are in a single module).  That being said, I
would likely just use the wrapper because I'm too lazy to copy the
examples into my code.  If I were entirely concerned about RAM usage,
I'd be writing in C.

=head1 METHODS

All constructors (C<with_>*) take as their first parameter one of:

=over 4

=item *

The name of the application, which gets passed in to Term::ReadLine's
constructor.

    my $term = Term::ReadLine::Event->with_Foo('myapp');

=item *

An array ref consisting of the name of the application, and the input
and output filehandles.  This is useful if you need to override
these filehandles.

    my $term = Term::ReadLine::Event->with_Foo(['myapp', \*STDIN, \*STDOUT]);

=item *

A pre-constructed Term::ReadLine object.  This is useful if you need
to do other things with the Term::ReadLine object prior to setting up
the event loop, or if you have a custom package derived from Term::ReadLine
and you do not want Term::ReadLine::Event to create the default type.

    my $term = Term::ReadLine::Special->new('myapp', other => 'stuff');
    $term = Term::ReadLine::Event->with_Foo($term);

=back

Parameters for setting up the event loop, if any are required, will be
after this first parameter as named parameters, e.g.:

   Term::ReadLine::Event->with_IO_Async('myapp', loop => $loop);

All constructors also assume that the required module(s) is(are) already
loaded.  That is, if you're using with_AnyEvent, you have already loaded
AnyEvent (and thus the event loop it is using); if you're using with_POE,
you have already loaded POE, etc.

=head2 with_AnyEvent

Creates a L<Term::ReadLine> object and sets it up for use with L<AnyEvent>.

=head2 with_Coro

Creates a L<Term::ReadLine> object and sets it up for use with L<Coro>.

=head2 with_IO_Async

Creates a L<Term::ReadLine> object and sets it up for use with L<IO::Async>.

Parameters:

=over 4

=item loop

The IO::Async loop object to integrate with.

=back

=head2 with_POE

Creates a L<Term::ReadLine> object and sets it up for use with L<POE>.

=head2 with_Reflex

Creates a L<Term::ReadLine> object and sets it up for use with L<Reflex>.

=head2 with_Tk

Creates a L<Term::ReadLine> object and sets it up for use with L<Tk>.

=head2 DESTROY

During destruction, we attempt to clean up.  Note that L<Term::ReadLine>
does not like to have a second T::RL object created in the same process.
This means that you should only ever let the object returned by the
constructors to go out of scope when you will I<never use Term::ReadLine
again in that process>.

This largely makes destruction moot, but it can be nice in some scenarios
to clean up after oneself.

=head2 trl

Access to the Term::ReadLine object itself.  Since Term::ReadLine::Event
is not a Term::ReadLine, but HAS a Term::ReadLine, this gives access to
the underlying object in case something isn't exposed sufficiently.  This
should not be an issue since T::RL::E automatically maps any call it doesn't
recognise directly on to the underlying T::RL.

=head1 AUTHOR

Darin McBride, C<< <dmcbride at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-term-readline-event at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-ReadLine-Event>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::ReadLine::Event

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-ReadLine-Event>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Term-ReadLine-Event>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Term-ReadLine-Event>

=item * Search CPAN

L<http://search.cpan.org/dist/Term-ReadLine-Event/>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item Paul "LeoNerd" Evans <leonerd@leonerd.org.uk>

For all the examples (IO-Async, IO-Poll, select, and fixes for AnyEvent).

=item Rocco Caputo <rcaputo@cpan.org>

For a final patch to Term::ReadLine that helps reduce the number
of variables that get closed upon making much of this easier to handle.

For the POE and Reflex examples, and a push to modularise the examples.

=item P5P

For genericising my initial AnyEvent patch idea.

=back

=head1 AUTHOR

Darin McBride <dmcbride@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Darin McBride and others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
