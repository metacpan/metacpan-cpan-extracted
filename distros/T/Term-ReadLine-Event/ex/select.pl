#!/usr/bin/perl

use strict;
use warnings;

use Term::ReadLine 1.09;

use File::Basename;
use lib dirname($0) . '/lib';
use ExampleHelpers qw(
  initialize_completion update_time print_input
);

my $term = Term::ReadLine->new('...');
initialize_completion($term);

# Presumably, if you're using this loop, you're also selecting on other
# fileno's.  It is up to you to add that in to the wait callback (first
# one passed to event_loop) and deal with those file handles.

$term->event_loop(
                  sub {
                      # This callback is called every time T::RL wants to
                      # read something from its input.  The parameter is
                      # the return from the other callback.
                      my $fileno = shift;
                      my $rvec = '';
                      vec($rvec, $fileno, 1) = 1;
                      while(1) {
                          select my $rout = $rvec, undef, undef, 1.0;
                          last if vec($rout, $fileno, 1);
                          update_time();
                      }
                  },
                  sub {
                      # This callback is called as the T::RL is starting up
                      # readline the first time.  The parameter is the file
                      # handle that we need to monitor.  The return value
                      # is used as input to the previous callback.

                      # We return the fileno that we will use later.

                      # cygwin/TRL::Gnu seems to use some other object here
                      # that doesn't respond to a fileno method call (rt#81344)
                      fileno($_[0]);
                  }
                 );

my $input = $term->readline('> ');

# No further cleanup required

print_input($input);
