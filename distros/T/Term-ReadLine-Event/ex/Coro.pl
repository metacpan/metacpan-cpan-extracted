#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent;
use Coro;
use Coro::AnyEvent;
use Coro::Handle;
use Term::ReadLine 1.09;

use File::Basename;
use lib dirname($0) . '/lib';
use ExampleHelpers qw(
  initialize_completion update_time print_input
);

async {
    while (1)
    {
        # use a Coro-safe sleep.
        Coro::AnyEvent::sleep 1;
        update_time();
    }
};

my $term = Term::ReadLine->new('...');
initialize_completion($term);

# set up the event loop callbacks.
$term->event_loop(
                  sub {
                      # This callback is called every time T::RL wants to
                      # read something from its input.  The parameter is
                      # the return from the other callback.

                      # Tell Coro to wait until we have something to read,
                      # and then we can return.
                      shift->readable();
                  }, sub {
                      # This callback is called as the T::RL is starting up
                      # readline the first time.  The parameter is the file
                      # handle that we need to monitor.  The return value
                      # is used as input to the previous callback.

                      # in Coro, we just need to unblock the filehandle,
                      # and save the unblocked filehandle.
                      unblock $_[0];
                  }
                 );


my $input = $term->readline('> ');

# when we're completely done, we can do this.  Note that this still does not
# allow us to create a second T::RL, so only do this when your process
# will not use T::RL ever again.  Most of the time we shouldn't need this,
# though some event loops may require this.  Reading AnyEvent::Impl::Tk
# seems to imply that not cleaning up may cause crashes, for example.
# (And Coro uses AnyEvent under the covers.)
$term->event_loop(undef);

# No further cleanup required other than letting the filehandle go out of scope
# and thus deregister.

print_input($input);
