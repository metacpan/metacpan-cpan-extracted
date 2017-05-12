#!/usr/bin/perl

use strict;
use warnings;

use IO::Poll qw( POLLIN );
use Term::ReadLine 1.09;
use File::Basename;
use lib dirname($0) . '/lib';
use ExampleHelpers qw(
  initialize_completion update_time print_input
);


my $term = Term::ReadLine->new('...');
initialize_completion($term);

# If you're using IO::Poll, it's presumably because you are also polling
# other filehandles.  We thus use a global one and close on it.
my $poll = IO::Poll->new;

# We use this to track the filehandle so we can remove it later.
# We could also use $term->IN, but this way we know that it always
# matches the filehandle we have masked.
my $fh;

# set up the event loop callbacks.
$term->event_loop(
                  sub {
                      # This callback is called every time T::RL wants to
                      # read something from its input.  The parameter is
                      # the return from the other callback.
                      while(1) {
                          $poll->poll( 1.0 );
                          last if $poll->events( $fh );
                          update_time();
                      }
                  },
                  sub {
                      # This callback is called as the T::RL is starting up
                      # readline the first time.  The parameter is the file
                      # handle that we need to monitor.  The return value
                      # is used as input to the previous callback.

                      $fh = shift;
                      $poll->mask( $fh => POLLIN );
                      return;
                  }
                 );

my $input = $term->readline('> ');

#$term->event_loop(undef);
$poll->remove($fh);

print_input($input);
